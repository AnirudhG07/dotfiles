import { div, image, uniform_list } from "gpui-kit";
import { v_flex, TextView, Scrollbar } from "gpui-base";

export function markdownView(panel, colors) {
  const blocks = panel.markdownBlocks || [{ text: panel.text || "" }], headings = panel.headings || [];
  const start = Math.max(0, panel.anchor ? blocks.findIndex(block => block.heading?.slug === panel.anchor) : 0);
  const body = v_flex().id("preview-markdown").flex_1().min_h(0).min_w(0);
  if (panel.contents && headings.length) {
    const id = "preview-contents-list";
    body.child(div().relative().h(Math.min(180, headings.length * 28)).flex_none().border_b(0.5).border_color(colors.border)
      .child(uniform_list(id, headings.length, i => headings[i].slug, range => headings.slice(range.start, range.end).map(h =>
        div().h(28).pl(16 + (h.level - 1) * 12).pr(12).flex().items_center().text_size(12).truncate()
          .when(h.slug === panel.anchor, el => el.bg(colors.selected)).child(h.title)))
        .size_full().on_item_click((slug, cx) => panel.follow("#" + encodeURIComponent(slug), cx)))
      .child(Scrollbar.vertical(id).absolute().right(0).top(0).bottom(0)));
  }
  if (panel.anchor) body.child(div().id("preview-whole-document").h(28).px(16).flex_none().flex().items_center().text_size(12)
    .border_b(0.5).border_color(colors.border).text_color(colors.muted).cursor_default().role("button").accessibility_label("Show whole document")
    .hover(s => s.bg(colors.hover).text_color(colors.foreground))
    .on_click((_event, cx) => { cx.stop_propagation(); panel.follow("#", cx); }).child("↑ Whole document"));
  return body.child(v_flex().id(`preview-markdown-${panel.selected.file}-${panel.anchor || "top"}`).flex_1().min_h(0).min_w(0).overflow_y_scrollbar().p(16).gap(12)
    .on_size_change((size, cx) => panel.measure(size, cx))
    .children(blocks.slice(start).map((block, offset) => {
      const index = start + offset;
      if (block.diagram) {
        if (block.error) return v_flex().gap(6).flex_none().text_size(12)
          .child(div().text_color(colors.ansi1).child(`Mermaid: ${block.error}`))
          .child(TextView.markdown(`preview-diagram-source-${index}`, block.text).selectable(true).scrollable(false).w_full());
        // The native scrollbar wrapper otherwise defaults to the full available height.
        return div().id(`preview-diagram-${index}`).w_full().h(block.media.height).flex_none().overflow_x_scrollbar()
          .child(image(block.media.path).w(block.media.width).h(block.media.height));
      }
      if (!block.media) return TextView.markdown(`preview-markdown-${panel.selected.file}-${index}`, block.text)
        .selectable(true).scrollable(false).w_full().flex_none().text_size(13).text_color(colors.foreground).on_link_click((url, cx) => panel.follow(url, cx));
      const width = Math.min(block.media.width, Math.max(1, panel.viewport.width - 32));
      return div().id(`preview-markdown-image-${index}`).w(width).h(width * block.media.height / block.media.width).flex_none().cursor_default()
        .on_click((_event, cx) => panel.follow(block.href, cx)).child(image(block.media.path).size_full());
    })));
}
