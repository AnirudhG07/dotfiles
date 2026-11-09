// Idle reaper: parks agents that have been idle for hours (exits them and leaves the resume command typed at the
// shell prompt) and closes what nobody came back to. See reaper.js for the rules and README for the settings.
//
// It must stay alive to work, so give it a place in your layout where it takes no room:
//
//   { "id": "idle-reaper", "type": "block", "size": { "px": 0 }, "content": { "mod": "idle-reaper" } }
//
// A mod only runs while the window is open. `scripts/idle-reaper` runs the same code from a timer for when it is
// not (it does nothing while a window is up, so the two never act together). Only one copy acts at a time.

import { View, div } from "gpui-kit";
import { v_flex } from "gpui-base";
import { appHome, exec, focused, hc, home, placement, props, readTextFile, setShared, shared, theme, writeTextFile } from "herdr";
import { configPath, mergeConfig } from "./config.js";
import { Lease } from "./lease.js";
import { DEFAULTS } from "./reaper.js";
import { makeCwdOf, run } from "./runner.js";

const TICK_MS = 30000;
const FIRST_RUN_MS = 60000; // let statuses settle after the app starts

export default class IdleReaper extends View {
  init(_props, cx) {
    this.cfg = { ...DEFAULTS };
    this.ready = false;
    this.running = false;
    this.nextAt = Date.now() + FIRST_RUN_MS;
    this.stateText = null;
    this.log = [];
    this.lease = new Lease("idle-reaper.lease", { shared, setShared });
    cx.timer.every(TICK_MS, (cx) => {
      this.lease.beat();
      this.tick(cx);
    });
    cx.spawn(async (cx) => {
      let text = null;
      try {
        text = await readTextFile(configPath(appHome(), "idle-reaper", await this.envVar("HERDR_MODS_CONFIG_DIR")));
      } catch {}
      const { cfg, error } = mergeConfig(DEFAULTS, text, props());
      if (error) console.log("idle-reaper: config/idle-reaper.json ignored:", error);
      this.cfg = cfg;
      this.ready = true;
      cx.notify();
    });
  }

  close() {
    this.lease.release();
  }

  note(text) {
    this.log = [{ at: Date.now(), text }, ...this.log].slice(0, 12);
  }

  async envVar(name) {
    try {
      const r = await exec("printenv", [name]);
      return r.code === 0 ? r.stdout.trim() || null : null;
    } catch {
      return null;
    }
  }

  // The host's side of runner.js.
  io(cx) {
    const stateFile = `${appHome()}/idle-reaper-state.json`;
    return {
      home: home(),
      hc: async (args) => {
        try {
          const r = await hc(args);
          return { code: r.code, stdout: r.stdout };
        } catch {
          return { code: -1, stdout: "" };
        }
      },
      readText: (p) => readTextFile(p),
      cwdOf: makeCwdOf(async (cmd, args) => {
        const r = await exec(cmd, args);
        return { code: r.code, stdout: r.stdout };
      }),
      focusedTerminal: async () => focused()?.terminal ?? null,
      readState: async () => {
        this.stateText = await readTextFile(stateFile);
        try {
          return this.stateText ? JSON.parse(this.stateText) : {};
        } catch {
          return {};
        }
      },
      writeState: async (obj) => {
        const text = JSON.stringify(obj, null, 1);
        await writeTextFile(stateFile, text, this.stateText);
        this.stateText = text;
      },
      sleep: (ms) => new Promise((resolve) => cx.timer.after(ms, resolve)),
      log: (l) => this.note(l),
    };
  }

  tick(cx) {
    if (!this.ready || !this.cfg.enabled || this.running || !this.lease.holds() || Date.now() < this.nextAt) return;
    this.running = true;
    this.nextAt = Date.now() + Math.max(60, Number(this.cfg.interval_s) || 600) * 1000;
    cx.spawn(async (cx) => {
      try {
        await run(this.cfg, this.io(cx));
      } catch (e) {
        this.note(`pass failed: ${String(e)}`);
      }
      this.running = false;
      cx.notify();
    });
  }

  render(cx) {
    if (placement()) return div(); // floating: nothing to draw
    const t = theme();
    const time = (ms) => new Date(ms).toLocaleTimeString([], { hour12: false });
    const next = Math.max(0, Math.round((this.nextAt - Date.now()) / 60000));
    return v_flex().size_full().overflow_hidden().bg(t.surface).p(12).gap(4).text_size(12).text_color(t.muted)
      .child(div().text_size(13).font_semibold().text_color(t.foreground).child("Idle reaper"))
      .child(div().child(`${this.cfg.enabled ? (this.cfg.dry_run ? "dry run" : "on") : "off"} · ${this.lease.holds() ? "acting" : "standing by (another copy holds the lease)"} · next pass in ${next} min`))
      .child(div().child(`park after ${Math.round(this.cfg.park_after_s / 3600)} h idle · close parked after ${Math.round(this.cfg.close_after_s / 3600)} h · ${this.cfg.groups.length} group${this.cfg.groups.length === 1 ? "" : "s"}`))
      .children(this.log.map((l) => div().text_color(t.dim).child(`${time(l.at)}  ${l.text}`)));
  }
}
