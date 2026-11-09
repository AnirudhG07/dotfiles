// Runs one idle-reaper pass against herdr-core. Host-free: everything the host provides comes in through `io`,
// so the Herdr mod (main.js) and the headless script (scripts/idle-reaper) share this code and the tests can fake it.
//
// io:
//   hc(args)            run `hc <args>` -> {code, stdout}
//   readText(path)      file text or null
//   cwdOf(pid)          the working directory of a process, or null
//   focusedTerminal()   address of the terminal the window has focused, or null (no window)
//   readState() / writeState(obj)
//   sleep(ms)           promise
//   log(line)
//   home                the home folder
//
// Parking types the resume command with `hc keys`. That cannot type `_ : & ~ (` and capitals, so a command that
// needs them, or a terminal whose shell sits in another folder than the agent (it would need a `cd`), is not parked.

import { IDLE, appFor, plan, describeGroupClose, resumeCommand, typable } from "./reaper.js";

const base = (p) => String(p ?? "").split("/").pop();

/** Whether two folder paths are the same folder (a trailing slash does not matter). */
export const samePath = (a, b) => Boolean(a && b) && String(a).replace(/\/+$/, "") === String(b).replace(/\/+$/, "");

/** The folder in `lsof -a -d cwd -p PID -Fn` output (`p123`, `fcwd`, `n/the/path` on separate lines), or null. */
export function parseLsofCwd(text) {
  const line = String(text ?? "").split("\n").find((l) => l.startsWith("n"));
  return line && line.length > 1 ? line.slice(1) : null;
}

/**
 * A process's current folder. Linux has /proc; macOS has none, so it asks lsof (/usr/sbin, which a launchd job's
 * PATH may not list). `exec(cmd, args)` resolves `{code, stdout}`. Null when neither works: the caller then does
 * not park, because it cannot tell whether the shell is in the agent's folder.
 */
export function makeCwdOf(exec) {
  return async (pid) => {
    if (!pid) return null;
    try {
      const r = await exec("readlink", ["-f", `/proc/${pid}/cwd`]);
      if (r.code === 0 && r.stdout.trim()) return r.stdout.trim();
    } catch {}
    for (const lsof of ["lsof", "/usr/sbin/lsof"]) {
      try {
        const r = await exec(lsof, ["-a", "-d", "cwd", "-p", String(pid), "-Fn"]);
        const cwd = r.code === 0 ? parseLsofCwd(r.stdout) : null;
        if (cwd) return cwd;
      } catch {}
    }
    return null;
  };
}

/** `path` with these folders added at the front when they are missing (a launchd or cron job starts with a bare PATH). */
export function augmentPath(path, folders) {
  const have = String(path ?? "").split(":").filter(Boolean);
  return [...folders.filter((f) => f && !have.includes(f)), ...have].join(":");
}
const expand = (p, home) => (p.startsWith("~/") ? `${home}/${p.slice(2)}` : p);

async function hcJson(io, args) {
  const r = await io.hc([...args, "--json"]);
  if (!r || r.code !== 0) return null;
  try {
    return JSON.parse(r.stdout);
  } catch {
    return null;
  }
}

/** The session id of an agent terminal, or null. */
export async function sessionOf(app, g, io) {
  if (app.session_label) return g.labels?.[app.session_label] || null;
  const pid = g.foreground?.pid;
  if (app.session_file && pid) {
    try {
      const v = JSON.parse((await io.readText(expand(app.session_file.replace("{pid}", pid), io.home))) ?? "null");
      return v?.[app.session_key ?? "sessionId"] || null;
    } catch {
      return null;
    }
  }
  return null;
}

/** Every live terminal worth looking at, as plan() wants it. */
export async function gather(cfg, state, io) {
  const ls = await hcJson(io, ["ls"]);
  if (!ls) throw new Error("hc ls failed");
  const focused = io.focusedTerminal ? await io.focusedTerminal() : null;
  const terms = [];
  const known = Object.keys(cfg.apps).flatMap((k) => cfg.apps[k].match ?? [k]);
  for (const t of ls.terminals ?? []) {
    if (t.state !== "live") continue;
    // a shell that holds a parked resume command has no status of its own: look at those too
    const wanted = t.status || t.name || t.address in state || known.includes(String(t.agent));
    if (!wanted) continue;
    const g = await hcJson(io, ["get", t.address]);
    if (!g) continue;
    const st = g.status ?? {};
    const fgName = base(g.foreground?.name);
    const appKey = appFor(cfg.apps, st.app, fgName);
    const hasStatus = Boolean(st.state);
    terms.push({
      key: t.address,
      token: `${t.address}@${g.created_ms}`,
      name: g.name ?? null,
      app: hasStatus ? appKey : null,
      status: st.state ?? null,
      idle_since: IDLE.has(st.state) && g.status_ms ? g.status_ms / 1000 : null,
      focused: t.address === focused,
      hasStatus,
      title: String(g.title ?? "").replace(/^[^\p{L}\p{N}]+/u, ""),
      cwd: g.foreground?.cwd ?? g.cwd,
      pid: g.foreground?.pid ?? null,
      shell_pid: g.pid,
      argv0: base(g.argv?.[0]),
      session: hasStatus && appKey ? await sessionOf(cfg.apps[appKey], g, io) : null,
    });
  }
  return terms;
}

async function park(cfg, t, io) {
  const app = cfg.apps[t.app];
  const cmd = resumeCommand(app, t.session);
  const first = String(app.resume).split(" ")[0];
  if (t.argv0 === first || t.argv0 === "env") return null; // the terminal runs the agent itself: no shell to land in
  if (!typable(cmd)) return null;
  const shellCwd = await io.cwdOf(t.shell_pid);
  if (!samePath(shellCwd, t.cwd)) {
    io.log(`${t.key} not parked: shell is in ${shellCwd ?? "?"}, agent in ${t.cwd} (hc keys can't type a cd)`);
    return null;
  }
  if (cfg.dry_run) return cmd;
  await io.hc(["send", t.key, "/exit"]);
  let gone = false;
  for (let i = 0; i < 20 && !gone; i++) {
    await io.sleep(1000);
    const g = await hcJson(io, ["get", t.key]);
    if (!g || g.state !== "live") return null; // the terminal went away with the agent
    gone = !g.status && base(g.foreground?.name) !== first;
  }
  if (!gone) {
    io.log(`${t.key} did not exit, leaving it`);
    return null;
  }
  await io.sleep(1000);
  const args = [...cmd].map((c) => (c === " " ? "space" : c));
  const r = await io.hc(["keys", t.key, ...args]);
  if (!r || r.code !== 0) {
    io.log(`${t.key} could not type the resume command`);
    return null;
  }
  return cmd;
}

async function close(cfg, key, io) {
  if (cfg.dry_run) return;
  await io.hc(["kill", key]);
  for (let i = 0; i < 10; i++) {
    await io.sleep(500);
    const g = await hcJson(io, ["get", key]);
    if (!g || g.state !== "live") break;
  }
  await io.hc(["rm", key]);
}

const hasText = async (io, key, needle) => {
  const r = await io.hc(["read", key]);
  return Boolean(r && r.code === 0 && r.stdout.replace(/\n/g, "").includes(needle));
};

/** One pass. Returns the log lines it wrote. */
export async function run(cfg, io, now = Date.now() / 1000) {
  const lines = [];
  const logOne = (l) => {
    lines.push(l);
    io.log(l);
  };
  const log = { ...io, log: logOne };
  const state = (await io.readState()) ?? {};
  const terms = await gather(cfg, state, log);
  const p = plan({ cfg, terms, state, now });
  const next = { ...p.keep };

  for (const j of p.closeParked) {
    if ((await hasText(log, j.key, j.ent.cmd)) || cfg.dry_run) {
      logOne(`close ${j.key} (${j.ent.title ?? ""})`);
      await close(cfg, j.key, log);
    } else logOne(`${j.key} parked pane was touched, forgetting it`);
  }
  for (const j of p.closeGroup) {
    logOne(describeGroupClose(j));
    await close(cfg, j.key, log);
  }
  for (const j of p.park) {
    const cmd = await park(cfg, j.term, log);
    if (!cmd) continue;
    logOne(`park ${j.key} (${j.ent.title ?? ""}): ${cmd}`);
    next[j.key] = { ...j.ent, parked: true, cmd };
  }
  if (!cfg.dry_run) await io.writeState(next);
  return lines;
}
