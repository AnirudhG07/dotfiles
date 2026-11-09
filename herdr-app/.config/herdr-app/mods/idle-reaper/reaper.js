// What idle-reaper decides, with no host imports so `node --test` runs it.
//
// Agents that sit idle pile up. Two things are done about it:
//
//   park   An agent pane idle for `park_after_s` is exited and its resume command (`claude --resume <id>`) is
//          typed at the shell prompt without Enter, so one keypress brings the session back.
//   close  A parked pane nobody touched for `close_after_s` (counted from when it went idle) is closed for good.
//
// `groups` handle sessions that should not be parked at all, only bounded, e.g. one agent per chat topic:
//   { name, match: "<regex on the terminal name>", exempt: "<regex: never touched>", close_after_s, max_live, min_idle_s }
//   - idle for `close_after_s` is closed;
//   - beyond `max_live` the least recently used are closed even if younger, but never one idle less than `min_idle_s`.
//
// Never touched: a focused terminal, one that is working or blocked, a named terminal outside every group.

export const DEFAULTS = {
  enabled: true,
  dry_run: false, // log what would happen, change nothing
  interval_s: 600, // how often the mod looks
  park_after_s: 4 * 3600,
  close_after_s: 3 * 86400,
  // What an agent is called by `hc` (status.app, else the foreground program) -> how to resume it.
  //   resume        command template; {id} is the session id
  //   session_file  JSON file holding the id; {pid} is the agent's pid; session_key names the field
  //   session_label terminal label holding the id
  // A command the terminal cannot type (hc keys has no `_ : & ~ (`) is closed rather than parked.
  apps: {
    "claude-code": { match: ["claude-code", "claude"], resume: "claude --resume {id}", session_file: "~/.claude/sessions/{pid}.json", session_key: "sessionId" },
    opencode: { match: ["opencode"], resume: "opencode --session {id}", session_label: "opencode.session" },
  },
  groups: [],
};

export const IDLE = new Set(["idle", "done"]);

/** The key of the `apps` entry that matches what hc reported, or null. */
export function appFor(apps, ...names) {
  for (const name of names) {
    if (!name) continue;
    for (const [key, a] of Object.entries(apps ?? {})) if ((a.match ?? [key]).includes(name)) return key;
  }
  return null;
}

/** Whether `hc keys` can type every character (it has no names for `_ : & ~ (` and capitals). */
export const typable = (s) => /^[a-z0-9 .,/;'\\-]+$/.test(s);

/** The resume command for an app and session id. */
export const resumeCommand = (app, id) => String(app.resume).replace("{id}", id);

/** Regexes that fail to compile never match. */
function re(src) {
  try {
    return src ? new RegExp(src, "u") : null;
  } catch {
    return null;
  }
}

/**
 * @param {object} i
 *   cfg    settings (DEFAULTS merged with config/idle-reaper.json)
 *   terms  `[{key, token, name, app, status, idle_since, focused, session, hasStatus}]`
 *          key: the terminal's address; token: changes when the address is reused;
 *          app: an `apps` key or null; status: idle/done/working/blocked or null;
 *          idle_since: seconds since the epoch when it went idle, or null; hasStatus: reports a status at all.
 *   state  what the last run kept: `{[key]: {terminal_id, idle_since, title?, parked?, cmd?}}`
 *   now    seconds since the epoch
 * @returns `{keep, park, closeParked, closeGroup}` — `keep` is the next state; the others are jobs for the runner.
 */
export function plan({ cfg, terms, state = {}, now }) {
  const keep = {};
  const park = [];
  const closeParked = [];
  const closeGroup = [];
  const groups = (cfg.groups ?? []).map((g) => ({ ...g, rx: re(g.match), exempt: re(g.exempt), members: [] }));

  for (const t of terms) {
    const prev = state[t.key];
    const old = prev && prev.terminal_id === t.token ? prev : null;

    if (old?.parked) {
      if (t.hasStatus) continue; // someone resumed it: forget
      if (now - old.idle_since >= cfg.close_after_s) closeParked.push({ key: t.key, ent: old });
      else keep[t.key] = old;
      continue;
    }

    const group = t.name ? groups.find((g) => g.rx?.test(t.name)) : null;
    if (group) {
      if (!IDLE.has(t.status) || t.focused) continue;
      const ent = old ?? { terminal_id: t.token, idle_since: t.idle_since ?? now };
      if (group.exempt?.test(t.name)) keep[t.key] = ent;
      else group.members.push({ key: t.key, name: t.name, ent });
      continue;
    }

    if (!t.app || t.name || t.focused || !IDLE.has(t.status) || !t.session) continue;
    const ent = old ?? { terminal_id: t.token, idle_since: t.idle_since ?? now };
    ent.title = t.title ?? ent.title;
    if (cfg.park_after_s > 0 && now - ent.idle_since >= cfg.park_after_s) park.push({ key: t.key, ent, term: t });
    else keep[t.key] = ent;
  }

  for (const g of groups) {
    g.members.sort((a, b) => a.ent.idle_since - b.ent.idle_since); // least recently used first
    const excess = g.max_live > 0 ? Math.max(0, g.members.length - g.max_live) : 0;
    g.members.forEach((m, idx) => {
      const idle = now - m.ent.idle_since;
      const overCap = idx < excess && idle >= (g.min_idle_s ?? 0);
      const overAge = g.close_after_s > 0 && idle >= g.close_after_s;
      if (overCap || overAge) closeGroup.push({ key: m.key, name: m.name, group: g.name, idle, reason: overCap ? "over cap" : "idle" });
      else keep[m.key] = m.ent;
    });
  }
  return { keep, park, closeParked, closeGroup };
}

const fmtH = (s) => `${(s / 3600).toFixed(1)}h`;

/** One log line for a closed group member. */
export const describeGroupClose = (c) => `close ${c.group ?? "group"} session ${c.name} (${c.key}) ${c.reason} ${fmtH(c.idle)}`;
