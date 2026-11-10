// Popup terminal: a command runs in a floating terminal window over the layout, like tmux's display-popup.
// It closes itself when the program exits (the overlay ends with its terminal) or with the title bar's ✕.
//
// Keys (keys.json) send "<mod>.<name>": "cmd-/": "popup-term.shell", "cmd-g": "popup-term.lazygit", "cmd-y": "popup-term.yazi".
// Remote machines that need a password again (`hc machine ls`: needs_login) get a login popup by themselves,
// one machine at a time, once per time it happens; `herdr-app do popup-term.login` asks again right away.
//
// Edit POPUPS below to add one. It needs a zero-size block in the layout so it is always alive:
//   { "id": "popup-term", "type": "block", "size": { "px": 0 }, "content": { "mod": "popup-term" } }

import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { exec, focused, home, nextCommand, openOverlay, closeOverlay, props, run, spaces, terminals, theme, notify } from "herdr";

// name -> { argv: program + args (omit: the default shell), title, w, h: share of the window }
const POPUPS = {
  shell: { title: "Terminal", w: 0.75, h: 0.75 },
  lazygit: { argv: ["lazygit"], title: "lazygit", w: 0.9, h: 0.9 },
  yazi: { argv: ["yazi"], title: "yazi", w: 0.9, h: 0.9 },
};

export default class PopupTerm extends View {
  init(_props, cx) {
    // The overlay's title-bar copy has props.bar and only draws.
    if (props()?.bar) return;
    this.asked = new Set(); // machines already given a login popup while they need one
    cx.timer.after(4000, (cx) => this.checkLogins(cx));
    cx.timer.every(20000, (cx) => this.checkLogins(cx));
    cx.spawn(async (cx) => {
      for (;;) {
        const name = (await nextCommand()).trim();
        // Touching cx is what ends this loop when the mod is saved and reloaded: otherwise the old build
        // keeps waiting here and answers keys with its old list.
        cx.notify();
        if (name === "login") {
          this.asked.clear();
          this.checkLogins(cx);
          continue;
        }
        const spec = POPUPS[name];
        if (!spec) {
          notify({ title: "Popup terminal", body: `no popup named "${name}"`, level: "error" });
          continue;
        }
        // The same key again closes its popup.
        const up = this.up?.[name];
        if (up && terminals().some((t) => t.address === up.address && t.state === "live")) {
          run("terminal.kill", { terminal: up.address });
          closeOverlay(up.id);
          continue;
        }
        await this.open(name, spec, cx);
      }
    });
  }

  // A machine that says needs_login gets `hc machine login <name>` in a popup here: it asks for the password (or
  // code) and the machine comes back. Closing the popup without logging in doesn't make it ask again until the
  // machine has been logged in and needs it once more (or popup-term.login).
  checkLogins(cx) {
    if (this.checking) return;
    this.checking = true;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("hc", ["machine", "ls", "--json"]);
        const need = (JSON.parse(r.stdout).machines ?? []).filter((m) => m.state === "needs_login").map((m) => m.name);
        for (const n of [...this.asked]) if (!need.includes(n)) this.asked.delete(n);
        const up = this.up?.login;
        if (up && terminals().some((t) => t.address === up.address && t.state === "live")) return; // one at a time
        const next = need.find((n) => !this.asked.has(n));
        if (!next) return;
        this.asked.add(next);
        const script =
          'echo "$1 needs you to log in again."; echo; ' +
          'if hc machine login "$1"; then echo; echo "logged in."; sleep 1; ' +
          'else echo; echo "login did not finish. Press Enter to close (it will not ask again until next time)."; read _; fi';
        await this.open("login", { local: true, title: `Log in: ${next}`, w: 0.55, h: 0.45, argv: ["sh", "-c", script, "sh", next] }, cx);
      } catch {
      } finally {
        this.checking = false;
      }
    });
  }

  // Where the popup should run, from the terminal that has focus:
  //  - a space on another Herdr machine: `hc run --on <machine>`, in that terminal's folder there;
  //  - a local terminal running ssh: the same ssh, with -t, running the program (a remote folder is not
  //    known from here, so it starts in the remote home);
  //  - otherwise: this computer, in the terminal's folder.
  async target() {
    const f = focused();
    const machine = spaces().find((s) => s.id === f?.space)?.machine || null;
    const out = { machine, cwd: f?.cwd || (machine ? null : home()), ssh: null };
    if (machine || !f?.terminal) return out;
    try {
      const r = await exec("hc", ["get", f.terminal]);
      const fg = JSON.parse(r.stdout)?.foreground;
      if (fg?.argv?.[0]?.split("/").pop() === "ssh") out.ssh = fg.argv.slice(1);
    } catch {}
    return out;
  }

  async open(name, spec, cx) {
    const { machine, cwd, ssh } = spec.local ? { machine: null, cwd: home(), ssh: null } : await this.target();
    const args = ["run", "--bg", "--json", "--no-parent", "--rm"];
    if (machine) args.push("--on", machine);
    if (cwd && !ssh) args.push("--cwd", cwd);
    // Far side (an ssh session, or a Herdr machine): a login+interactive shell so PATH has yazi, lazygit and
    // friends, and a message that stays for a few seconds if the program isn't installed there.
    const remote = spec.argv
      ? `exec "$SHELL" -lic '${spec.argv.join(" ")} || { echo; echo "${spec.argv[0]}: not installed on this host"; sleep 4; }'`
      : null;
    if (ssh) {
      args.push("--", "ssh", "-t", ...ssh.filter((a) => a !== "-t"), ...(remote ? [remote] : []));
    } else if (machine && remote) {
      args.push("--", "sh", "-c", remote);
    } else if (spec.argv) {
      args.push("--", ...spec.argv);
    }
    const r = await exec("hc", args);
    let address = null;
    try { address = JSON.parse(r.stdout).address; } catch {}
    if (r.code !== 0 || !address) {
      notify({ title: `Popup terminal: ${name}`, body: (r.stderr || r.stdout || "could not start").trim().slice(0, 200), level: "error" });
      return;
    }
    // A modal dialog, not a window: a window never takes the keyboard (q and Esc would go to the pane below,
    // and pane.focus can't reach an overlay's terminal), a dialog hands its keys and Esc to the terminal.
    // Modal so a stray click beside it doesn't close it and leave its program running.
    const id = openOverlay({
      kind: "dialog",
      modal: true,
      width: spec.w,
      height: spec.h,
      layout: {
        type: "column",
        children: [
          { type: "block", size: { px: 30 }, content: { mod: "popup-term", props: { bar: true, title: spec.title, terminal: address } } },
          { type: "block", content: { terminal: address } },
        ],
      },
    });
    (this.up ??= {})[name] = { id, address };
  }

  render() {
    const p = props() ?? {};
    if (!p.bar) return div();
    const t = theme();
    return h_flex()
      .size_full()
      .px(12)
      .items_center()
      .bg(t.surface)
      .border_b(1)
      .border_color(t.border)
      .text_size(12)
      .child(div().flex_1().truncate().font_semibold().text_color(t.foreground).child(p.title ?? ""))
      .child(
        div()
          .id("close")
          .px(8)
          .py(2)
          .rounded(5)
          .text_color(t.muted)
          .cursor_pointer()
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .on_click((_e, cx) => {
            cx.stop_propagation();
            run("terminal.kill", { terminal: p.terminal });
            closeOverlay(p.overlay);
          })
          .child("✕"),
      );
  }
}
