// Parse top-level headings and fences once, using offsets into untouched source.
// Fence state applies to every language, so nested examples never become diagrams.
const titleText = value => value.replace(/!?(\[([^\]]*)\])\([^)]*\)/g, "$2")
  .replace(/<[^>]*>/g, "").replace(/(^|\s)__?([^_]+)__?(?=\s|$)/g, "$1$2")
  .replace(/[`*~]/g, "").replace(/\\([\p{P}\p{S}])/gu, "$1")
  .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').trim();

const columns = whitespace => [...whitespace].reduce((column, char) => char === "\t" ? column + 4 - column % 4 : column + 1, 0);
const ATX = /^ {0,3}(#{1,6})(?:[ \t]+(.*?)|[ \t]*)$/;
const FENCE = /^ {0,3}(`{3,}|~{3,})(.*)$/;
const LIST = /^( {0,3})(?:[-+*]|\d{1,9}[.)])([ \t]+|$)/;
const THEMATIC = /^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$/;

function listItem(value, marker) {
  const prefix = marker[0].length - marker[2].length, gap = columns(marker[0]) - prefix;
  const padding = gap >= 1 && gap <= 4 ? gap : 1;
  return { indent: prefix + padding, text: " ".repeat(Math.max(0, gap - padding)) + value.slice(marker[0].length) };
}

export function markdownStructure(text) {
  const lines = text.match(/[^\n]*\n|[^\n]+$/g) || [], headings = [], diagrams = [], used = new Set(), counts = new Map();
  let offset = 0, fence = null, previous = null, listIndent = null, listParagraph = false, listFence = null;
  const listLine = value => {
    // Only paragraph content can continue after its list indentation is omitted.
    // Inspect nested container prefixes, but never interpret fenced code as prose.
    for (;;) {
      const quote = /^ {0,3}>[ \t]?/.exec(value), nested = !listFence && LIST.exec(value);
      if (quote) value = value.slice(quote[0].length);
      else if (nested && !THEMATIC.test(value)) { value = listItem(value, nested).text; listParagraph = false; }
      else break;
    }
    const marker = FENCE.exec(value);
    if (listFence) {
      if (marker && marker[1][0] === listFence[0] && marker[1].length >= listFence.length && !marker[2].trim()) listFence = null;
      listParagraph = false; return;
    }
    if (marker && !(marker[1][0] === "`" && marker[2].includes("`"))) {
      listFence = marker[1]; listParagraph = false; return;
    }
    listParagraph = Boolean(value.trim()) && !ATX.test(value) && !THEMATIC.test(value) &&
      !(listParagraph && /^ {0,3}(?:=+|-+)[ \t]*$/.test(value)) &&
      !/^ {0,3}\[.*\]:/.test(value) && (listParagraph || !/^(?: {4}|\t)/.test(value));
  };
  const heading = (raw, level, start) => {
    const title = titleText(raw), base = title.toLowerCase().replace(/[^\p{L}\p{N}\p{M}\s_-]/gu, "").replace(/\s/g, "-") || "section";
    let suffix = counts.get(base) || 0, slug = suffix ? `${base}-${suffix}` : base;
    while (used.has(slug)) slug = `${base}-${++suffix}`;
    counts.set(base, suffix + 1);
    used.add(slug); headings.push({ title: title || "Untitled", level, slug, start });
  };
  for (const line of lines) {
    const value = line.replace(/\r?\n$/, ""), marker = FENCE.exec(value), atx = ATX.exec(value);
    if (!fence) {
      const list = LIST.exec(value), thematic = THEMATIC.test(value);
      const indent = columns(/^[ \t]*/.exec(value)[0]);
      // Leave list contents (including lazy continuation lines) in one native TextView.
      // Extracting a nested heading or fence would break the surrounding list syntax.
      if (listIndent !== null && (!value.trim() || indent >= listIndent ||
          (listParagraph && !list && !marker && !atx && !thematic && !/^ {0,3}>/.test(value)))) {
        if (!value.trim() || indent >= listIndent) listLine(value.replace(/^[ \t]*/, whitespace => " ".repeat(columns(whitespace))).slice(listIndent));
        previous = null; offset += line.length; continue;
      }
      listIndent = null; listParagraph = false; listFence = null;
      if (list && !thematic) {
        const item = listItem(value, list);
        listIndent = item.indent; listLine(item.text);
        previous = null; offset += line.length; continue;
      }
    }
    if (fence) {
      if (marker && marker[1][0] === fence.marker[0] && marker[1].length >= fence.marker.length && !marker[2].trim()) {
        if (fence.mermaid) diagrams.push({ start: fence.start, end: offset + line.length, source: text.slice(fence.body, offset), closed: true });
        fence = null;
      }
      previous = null;
    } else if (marker && !(marker[1][0] === "`" && marker[2].includes("`"))) {
      fence = { marker: marker[1], start: offset, body: offset + line.length, mermaid: marker[2].trim().toLowerCase() === "mermaid" };
      previous = null;
    } else {
      if (atx) { heading((atx[2] || "").replace(/[ \t]+#+[ \t]*$/, ""), atx[1].length, offset); previous = null; }
      else if (previous && /^ {0,3}(?:=+|-+)[ \t]*$/.test(value)) {
        heading(previous.text, value.trim()[0] === "=" ? 1 : 2, previous.start); previous = null;
      } else previous = value.trim() && !/^(?: {4}|\t| {0,3}(?:>|[-+*] |\d+[.)] |\[.*\]:))/.test(value) ? { text: value, start: offset } : null;
    }
    offset += line.length;
  }
  if (fence?.mermaid) diagrams.push({ start: fence.start, end: text.length, source: text.slice(fence.body), closed: false });
  return { headings, diagrams };
}
