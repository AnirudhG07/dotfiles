// Popup terminal: a command runs in a floating terminal window over the layout, like tmux's display-popup.
// It closes itself when the program exits (the overlay ends with its terminal) or with the title bar's ✕.
//
// Keys (keys.json) send "<mod>.<name>": "cmd-/": "popup-term.shell", "cmd-g": "popup-term.lazygit", "cmd-y": "popup-term.yazi".
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
    cx.spawn(async (cx) => {
      for (;;) {
        const name = (await nextCommand()).trim();
        // Touching cx is what ends this loop when the mod is saved and reloaded: otherwise the old build
        // keeps waiting here and answers keys with its old list.
        cx.notify();
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
    const { machine, cwd, ssh } = await this.target();
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
    const id = openOverlay({
      kind: "window",
      key: `popup-term-${name}`,
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
    // A window doesn't take the keyboard when it opens: give it to the terminal, or Esc and q go to the pane below.
    cx.timer.after(150, () => run("pane.focus", { terminal: address }));
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
