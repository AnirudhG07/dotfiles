import { div, uniform_list } from "gpui-kit";
import { v_flex, h_flex, Scrollbar } from "gpui-base";
import { jsonRows, LIMITS } from "./structured.js";

export function structuredView(panel, type, colors) {
  const data = panel.dataPreview;
  if (!data) return div().flex_1();
  if (data.error) return v_flex().flex_1().p(16).gap(8).text_size(12)
    .child(div().text_color(colors.ansi1).child(data.error))
    .child(div().text_color(colors.muted).child("Open Source to inspect or edit the original text."));
  const json = type === "json", visible = json ? jsonRows(data.value, panel.expanded) : data;
  const id = `preview-data-${panel.selected.file}-${type}`, rows = visible.rows;
  const column = v_flex().flex_1().min_h(0).min_w(0);
  if (visible.truncated) column.child(div().px(16).py(8).text_size(12).text_color(colors.muted).child("Preview limit reached. Source retains the complete text."));
  if (!rows.length) return column.child(div().p(16).text_size(12).text_color(colors.muted).child("No rows."));
  const tableWidth = json ? null : data.widths.reduce((a, b) => a + b, 48);
  const list = uniform_list(id, rows.length, index => json ? rows[index].path || "$" : String(index), range => rows.slice(range.start, range.end).map((row, offset) => {
    const index = range.start + offset;
    if (json) return h_flex().h(28).pl(12 + Math.min(row.depth, 16) * 16).pr(12).gap(6).items_center().text_size(12)
      .child(div().w(12).flex_none().text_color(colors.muted).child(row.expandable ? row.open ? "▾" : "▸" : ""))
      .when(row.key !== null, el => el.child(div().max_w(180).truncate().child(row.key + ":")))
      .child(div().flex_1().min_w(0).truncate().text_color(row.type === "string" ? colors.ansi2 : row.type === "number" ? colors.ansi5 : colors.muted).child(row.text));
    return h_flex().h(28).w(tableWidth).items_center().border_b(0.5).border_color(colors.border).text_size(12)
      .when(index === 0, el => el.bg(colors.raised).font_medium())
      .child(div().w(48).px(8).flex_none().text_color(colors.dim).child(String(index + 1)))
      .children(data.widths.map((width, cell) => div().w(width).px(8).flex_none().truncate().border_l(0.5).border_color(colors.border)
        .child((row[cell] || "").slice(0, LIMITS.cell).replace(/[\r\n]/g, " ↵ ") + ((row[cell] || "").length > LIMITS.cell ? "…" : ""))));
  })).flex_1().min_h(0).min_w(0).when(!json, el => el.w(tableWidth));
  if (json) list.on_item_click((path, cx) => panel.toggleJson(path === "$" ? "" : path, cx));
  return column.child(v_flex().id(id + "-area").relative().flex_1().min_h(0).min_w(0).when(!json, el => el.overflow_x_scrollbar())
    .child(list).child(Scrollbar.vertical(id).absolute().right(0).top(0).bottom(0)));
}
