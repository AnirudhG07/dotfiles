import { resolveLink, kind } from "./paths.js";
import { loadMedia } from "./media.js";
import { markdownStructure } from "./markdown-structure.js";
import { diagram } from "./mermaid.js";

// Keep code examples byte-for-byte unchanged while rewriting image destinations.
function withoutCode(text) {
  let fence = null;
  return text.split(/(?<=\n)/).map(line => {
    const marker = line.match(/^ {0,3}(`{3,}|~{3,})/);
    if (marker && !fence) { fence = marker[1]; return line.replace(/[^\n]/g, " "); }
    if (fence) {
      if (marker && marker[1][0] === fence[0] && marker[1].length >= fence.length && /^\s*$/.test(line.slice(marker[0].length))) fence = null;
      return line.replace(/[^\n]/g, " ");
    }
    if (/^(?: {4}|\t)/.test(line)) return line.replace(/[^\n]/g, " ");
    return line.replace(/(`+)([^`]|(?!\1)`)*?\1/g, value => " ".repeat(value.length));
  }).join("");
}

const label = value => value.trim().replace(/\s+/g, " ").toLowerCase();

export function imageReferences(text) {
  const visible = withoutCode(text), references = [], definitions = new Map();
  for (const match of visible.matchAll(/^ {0,3}\[([^\]\n]+)\]:\s*(<[^>\n]+>|[^\s]+)/gm)) {
    const raw = match[2], start = match.index + match[0].lastIndexOf(raw);
    if (!definitions.has(label(match[1]))) definitions.set(label(match[1]), { start: start + (raw[0] === "<" ? 1 : 0), end: start + raw.length - (raw[0] === "<" ? 1 : 0) });
  }
  for (const match of visible.matchAll(/!\[((?:\\.|[^\]\\\n])*)\](?:\[([^\]\n]*)\])?/g)) {
    if ((visible.slice(0, match.index).match(/\\+$/)?.[0].length || 0) % 2) continue;
    const after = match.index + match[0].length;
    if (visible[after] === "(" && match[2] === undefined) {
      let start = after + 1;
      while (/\s/.test(visible[start] || "") && start < visible.length) start++;
      let end = start, depth = 0, angle = false;
      if (visible[start] === "<") { angle = true; start++; end = visible.indexOf(">", start); if (end < 0) continue; }
      else {
        for (; end < visible.length; end++) {
          const c = visible[end];
          if (c === "\\") { end++; continue; }
          if (c === "(") depth++;
          else if (c === ")") { if (!depth) break; depth--; }
          else if (/\s/.test(c) && !depth) break;
        }
      }
      const tailStart = end + (angle ? 1 : 0), tail = visible.slice(tailStart).match(/^\s*(?:(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\((?:\\.|[^)\\])*\))\s*)?\)/);
      if (end > start && tail) references.push({ start, end, imageStart: match.index, imageEnd: tailStart + tail[0].length, alt: match[1] });
    } else {
      const definition = definitions.get(label(match[2] || match[1]));
      if (definition) references.push({ ...definition, imageStart: match.index, imageEnd: after, alt: match[1] });
    }
  }
  return references.map(ref => {
    const href = text.slice(ref.start, ref.end);
    // A linked image follows its enclosing link when clicked.
    const outer = visible[ref.imageStart - 1] === "[" ? visible.slice(ref.imageEnd).match(/^\]\((<[^>\n]+>|(?:\\.|[^\s)\n])+)(?:\s+"[^"]*")?\)/) : null;
    return { ...ref, href, ...(outer ? { imageStart: ref.imageStart - 1, imageEnd: ref.imageEnd + outer[0].length, link: outer[1].replace(/^<|>$/g, "") } : {}) };
  });
}

export async function stageMarkdown(text, target, look) {
  const blocks = [], files = new Set(), staged = new Map();
  const { headings, diagrams } = markdownStructure(text);
  const events = [
    ...headings.map(heading => ({ start: heading.start, end: heading.start, heading })),
    ...diagrams.map(value => ({ ...value, diagram: true })),
    ...imageReferences(text).map(value => ({ ...value, start: value.imageStart, end: value.imageEnd, image: true })),
  ].sort((a, b) => a.start - b.start || (a.heading ? -1 : 1));
  let unavailable = false, cursor = 0;
  let pendingHeading = null;
  const pushText = end => {
    if (end > cursor) { blocks.push({ text: text.slice(cursor, end), ...(pendingHeading ? { heading: pendingHeading } : {}) }); pendingHeading = null; }
    cursor = end;
  };
  let diagramCount = 0;
  for (const ref of events) {
    if (ref.start < cursor) continue;
    if (ref.heading) { pushText(ref.start); pendingHeading = ref.heading; continue; }
    if (ref.diagram) {
      pushText(ref.start);
      const block = { diagram: true, source: ref.source, text: text.slice(ref.start, ref.end) };
      try {
        if (!ref.closed) throw new Error("Unclosed Mermaid fence.");
        if (++diagramCount > 24) throw new Error("Diagram limit reached (24 per document).");
        block.media = await diagram(ref.source, look);
      } catch (error) { block.error = String(error.message || error); }
      blocks.push(block); cursor = ref.end; continue;
    }
    try {
      const link = resolveLink(target.file, ref.href);
      if (!link.file || kind(link.file) !== "image") continue;
      files.add(link.file);
      if (target.on) { unavailable = true; continue; }
      if (!staged.has(link.file)) staged.set(link.file, await loadMedia({ ...target, file: link.file }));
      pushText(ref.imageStart);
      // Herdr 0.1.11's TextView omits image nodes, including data URIs.
      // Keep Markdown text native and insert native image() blocks in the same flow.
      blocks.push({ media: staged.get(link.file), href: ref.link || ref.href, alt: ref.alt });
      cursor = ref.imageEnd;
    } catch { unavailable = true; }
  }
  pushText(text.length);
  if (!blocks.length) blocks.push({ text: "" });
  // Each TextView needs the document's reference definitions, including links
  // whose definitions occur after a native image block.
  const visible = withoutCode(text), definitions = [...visible.matchAll(/^ {0,3}\[[^\]\n]+\]:[^\n]*/gm)].map(match => text.slice(match.index, match.index + match[0].length)).join("\n");
  if (definitions && blocks.length > 1) for (const block of blocks) if (block.text && !block.diagram) block.text += "\n\n" + definitions;
  return { blocks, headings, files: [...files], unavailable };
}
