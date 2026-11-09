// Claude Manager: every skill, command, agent, MCP server, hook and plugin Claude Code loads
// from ~/.claude, on or off. manage.py reads them and writes the switch into ~/.claude/settings.json
// the native way (skillOverrides, permissions.deny Agent(name), deniedMcpServers, enabledPlugins,
// disableAllHooks); one hook, which has no native switch, is stashed and put back in place. Type to filter, Tab for the kind, ↑/↓ and Enter (or click) to flip.
// New Claude Code sessions pick a change up; a session already running keeps what it loaded.

// Look: the bottom bar's quota meters. Grey by default, one coral Claude mark,
// color only where it means something: amber marks what Claude Code no longer loads.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, v_virtual_list, VirtualListScrollHandle, Scrollbar } from "gpui-base";
import { header, field, kbd, kbdHint, chip, SIZE, CORAL } from "./kit.js";
import { theme, exec, appHome, props, closeOverlay } from "herdr";

const ROW = 28;
// ponytail: fixed list width (dialog 1040 - padding 32); a virtual list takes its width from a row.
const LIST_W = 1008;
// [list key, label, manage.py kind]; each has icons/<list key>.svg
const KINDS = [["skills", "Skills", "skill"], ["commands", "Commands", "command"], ["agents", "Agents", "agent"],
  ["mcp", "MCP", "mcp"], ["hooks", "Hooks", "hook"], ["plugins", "Plugins", "plugin"]];
const icon = (k) => svg(`mods/claude-manager/icons/${k}.svg`).size(12).flex_none();

export default class ClaudeManager extends View {
  init(_props, cx) {
    this.data = null;
    this.kind = "skills";
    this.offOnly = false;
    this.filter = "";
    this.at = 0;
    this.busy = new Set(); // "kind:id" being written
    this.status = "Reading ~/.claude…";
    this.lock = Promise.resolve(); // one write at a time: each is read-modify-write of settings.json
    this.script = `${appHome()}/mods/claude-manager/manage.py`;
    this.scroll = VirtualListScrollHandle.new();
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Search" });
    this.input.on("change", (_e, cx) => { this.filter = this.input.value(); this.at = 0; cx.notify(); });
    this.input.on("submit", (_e, cx) => this.flip(this.rows()[this.at], cx));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    cx.spawn((cx) => this.load(cx));
  }

  async load(cx) {
    try {
      const r = await exec("python3", ["-I", this.script, "list"]);
      if (r.code !== 0) throw new Error(r.stderr.trim().split("\n").at(-1) || `manage.py exited ${r.code}`);
      this.data = JSON.parse(r.stdout);
      this.status = null;
    } catch (e) {
      this.status = `Couldn't read Claude Code's config: ${e.message ?? e}`;
    }
    cx.notify();
  }

  rows() {
    const f = this.filter.toLowerCase();
    return (this.data?.[this.kind] ?? []).filter((x) => (!this.offOnly || !x.on)
      && (!f || x.name.toLowerCase().includes(f) || (x.event ?? "").toLowerCase().includes(f) || x.desc.toLowerCase().includes(f)));
  }

  flip(item, cx) {
    if (!item) return;
    const kind = KINDS.find(([k]) => k === this.kind)[2];
    const key = `${kind}:${item.id}`;
    if (this.busy.has(key)) return;
    const want = !item.on;
    item.on = want; // optimistic; load() below puts back what the file really says
    this.busy.add(key);
    cx.notify();
    this.write(cx, key, ["set", kind, item.id, want ? "on" : "off"], (ok, err) =>
      ok ? null : `Couldn't turn ${item.name} ${want ? "on" : "off"}: ${err}`);
  }

  // Runs manage.py in its own task (its own cx: a handler's cx is dead once it returns), one at a
  // time, then reloads what the files say. msg(ok, err) is the status line after.
  write(cx, key, args, msg) {
    cx.spawn(async (cx) => {
      const prev = this.lock;
      let release;
      this.lock = new Promise((r) => (release = r));
      let status;
      try {
        await prev;
        const r = await exec("python3", ["-I", this.script, ...args]);
        status = msg(r.code === 0, r.stderr.trim().split("\n").at(-1));
      } catch (e) {
        status = msg(false, e.message ?? String(e));
      } finally {
        release(); // never left pending or rejected: the next write always runs
      }
      this.busy.delete(key);
      await this.load(cx); // clears the status line
      this.status = status;
      cx.notify();
    });
  }

  // ⌘⌫ once names what goes, ⌘⌫ again moves it to the Trash (Finder's Put Back undoes it).
  trash(cx) {
    const x = this.rows()[this.at];
    const kind = KINDS.find(([k]) => k === this.kind)[2];
    if (!x || !["skill", "agent"].includes(kind)) return;
    if (this.confirm !== `${kind}:${x.id}`) {
      this.confirm = `${kind}:${x.id}`;
      this.status = `⌘⌫ again moves ${x.name} to the Trash${kind === "skill" ? ", its whole folder" : ""}`;
      return cx.notify();
    }
    this.confirm = null;
    this.busy.add(`${kind}:${x.id}`);
    this.status = `Moving ${x.name} to the Trash…`;
    cx.notify();
    this.write(cx, `${kind}:${x.id}`, ["delete", kind, x.id], (ok, err) =>
      ok ? `${x.name} is in the Trash` : `Couldn't trash ${x.name}: ${err}`);
  }

  setKind(k, cx) {
    this.kind = k;
    this.at = 0;
    this.scroll.scroll_to_item(0);
    cx.notify();
  }

  step(d, cx) {
    const n = this.rows().length;
    if (!n) return;
    this.at = Math.max(0, Math.min(n - 1, this.at + d));
    this.scroll.scroll_to_item(this.at);
    cx.notify();
  }

  // A grey switch: on is the normal state, so it stays quiet; off goes hollow.
  toggle(c, on, busy) {
    return h_flex().w(24).h(14).flex_none().rounded(7).p(2).border_1().border_color(on ? c.border : c.input)
      .when(on, (el) => el.justify_end().bg(c.border)).opacity(busy ? 0.5 : 1)
      .child(div().size(8).rounded(4).bg(on ? c.muted : c.dim));
  }

  // label + gauge + value, as the quota bar draws its 5h / 7d meters
  gauge(c, k, label, list) {
    const n = list.length, live = list.filter((x) => x.on).length;
    const p = n ? live / n : 1;
    return h_flex().id(`cm-g-${k}`).flex_none().gap(4).items_center()
      .tooltip(`${label}: ${live} of ${n} load in new sessions`).accessibility_label(`${label} ${live} of ${n} on`)
      .child(icon(k).text_color(c.dim))
      .child(h_flex().w(28).h(4).rounded(2).overflow_hidden().bg(c.border)
        .child(div().h_full().rounded(2).flex_basis(0).flex_grow(p).bg(c.muted))
        .child(div().h_full().flex_basis(0).flex_grow(1 - p)))
      .child(div().text_size(SIZE.meta).text_color(live < n ? c.working : c.muted).child(`${live}/${n}`));
  }

  // Hooks: the event names a group, so it shows on the group's first row only.
  row(x, sel, prev) {
    const c = theme();
    const kind = KINDS.find(([k]) => k === this.kind)[2];
    // No handlers in here: a virtual list's rows can't hold any (the list's on_item_click does clicks).
    return h_flex().h(ROW).w(LIST_W - 8).mx(4).px(8).gap(12).items_center().rounded(8).cursor_pointer().text_size(SIZE.body)
      .when(sel, (el) => el.bg(c.selected ?? c.hover))
      .child(this.toggle(c, x.on, this.busy.has(`${kind}:${x.id}`)))
      .when(this.kind === "hooks", (el) => el.child(div().w(136).flex_none().truncate().text_size(SIZE.meta).text_color(c.muted)
        .child(x.event && x.event !== prev?.event ? x.event : "")))
      .child(div().w(this.kind === "hooks" ? 220 : 300).flex_none().truncate().text_color(x.on ? c.foreground : c.dim)
        .when(sel || x.id === "*", (d) => d.font_medium()).child(x.name))
      .child(div().flex_1().min_w(0).truncate().text_size(SIZE.body).text_color(x.on ? c.muted : c.dim).child(x.desc || " "))
      .child(div().w(80).flex_none().text_right().text_size(SIZE.micro)
        .text_color(x.on ? c.dim : c.working).child(!x.on ? "off" : x.mode && x.mode !== "on" ? x.mode : ""));
  }

  render() {
    const c = theme();
    const rows = this.rows();
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const d = this.data;
    const kindChip = ([k, label]) => chip(c, `cm-kind-${k}`,
      h_flex().gap(6).items_center().child(icon(k).text_color(this.kind === k ? c.foreground : c.muted)).child(label),
      { on: this.kind === k, onClick: (_e, cx) => this.setKind(k, cx) });
    const sep = () => div().w(1).h(14).flex_none().bg(c.border);

    return v_flex().id("claude-manager").track_focus(this.handle).size_full().min_h(0).bg(c.popover).text_color(c.foreground).text_size(SIZE.title)
      .on_key_down((e, cx) => {
        const k = e.key;
        if (k === "escape") return closeOverlay(props().overlay);
        if (k === "backspace" && e.modifiers.platform) { this.trash(cx); return cx.stop_propagation(); }
        if (this.confirm) { this.confirm = null; this.status = null; }
        if (k === "down") this.step(1, cx);
        else if (k === "up") this.step(-1, cx);
        else if (k === "pagedown") this.step(10, cx);
        else if (k === "pageup") this.step(-10, cx);
        else if (k === "tab") { const i = KINDS.findIndex(([x]) => x === this.kind); this.setKind(KINDS[(i + (e.modifiers.shift ? KINDS.length - 1 : 1)) % KINDS.length][0], cx); }
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(header(c, { glyph: svg("mods/claude-manager/claude.svg").size(14).flex_none().text_color(CORAL), title: "Claude Manager", status: kbd(c, "Esc") }))
      .child(v_flex().flex_1().min_h(0).p(16).gap(12)
        .child(h_flex().gap(8).items_center()
          .child(field(c, Input.new(this.input).flex_1().min_w(0), true))
          .child(h_flex().flex_none().gap(2).children(KINDS.map(kindChip)))
          .child(chip(c, "cm-off", "Off only", { on: this.offOnly, onClick: (_e, cx) => { this.offOnly = !this.offOnly; this.at = 0; cx.notify(); } })))
        .when(Boolean(this.status), (el) => el.child(div().text_size(SIZE.meta).text_color(/^Couldn't/.test(this.status) ? c.blocked : this.confirm ? c.working : c.dim).child(this.status)))
        .child(v_flex().relative().w(LIST_W).flex_1().min_h(0)
          .when(rows.length > 0, (el) => el
            .child(v_virtual_list("cm-list", rows.length, ROW, (i) => rows[i].id,
              (range) => rows.slice(range.start, range.end).map((x, j) => this.row(x, range.start + j === this.at, rows[range.start + j - 1])))
              .track_scroll(this.scroll).size_full()
              .on_item_click((name, cx) => {
                const i = this.rows().findIndex((x) => x.id === name);
                if (i < 0) return;
                this.at = i;
                this.confirm = null;
                this.flip(this.rows()[i], cx);
              }))
            .child(Scrollbar.vertical("cm-list").absolute().inset_0()))
          .when(Boolean(d) && rows.length === 0, (el) => el.child(v_flex().items_center().gap(8).pt(48)
            .child(div().text_size(SIZE.title).text_color(c.muted).child(this.offOnly ? "Nothing is off here" : "Nothing matches"))
            .child(div().text_size(SIZE.meta).text_color(c.dim).child("Try another word, or another kind")))))
        .child(h_flex().flex_none().gap(12).items_center()
          .child(kbdHint(c, "↵", "on / off"))
          .child(kbdHint(c, "Tab", "kind"))
          .when(this.kind === "skills" || this.kind === "agents", (el) => el.child(kbdHint(c, "⌘⌫", "Trash")))
          .child(div().flex_1())
          .when(Boolean(d), (el) => el.children(KINDS.flatMap(([k, label], i) => [...(i ? [sep()] : []), this.gauge(c, k, label, d[k])])))));
  }
}
