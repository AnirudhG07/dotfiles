// JSON Pointer rows and a quote-state CSV parser follow the pure-data approach of
// gsydler/cria-file-preview (Apache-2.0). This implementation adds strict parsing,
// bounded traversal and keeps the original source as the only editable value.
export const LIMITS = { rows: 10000, columns: 100, depth: 64, cell: 500 };
export const pointer = (path, key) => `${path}/${String(key).replaceAll("~", "~0").replaceAll("/", "~1")}`;
const container = value => value !== null && typeof value === "object";

export function jsonRows(value, expanded, limits = LIMITS) {
  const rows = [], stack = [{ value, path: "", depth: 0, key: null }];
  let truncated = false;
  while (stack.length && rows.length < limits.rows) {
    const node = stack.pop(), branch = container(node.value), keys = branch ? Object.keys(node.value) : [];
    const array = Array.isArray(node.value), expandable = branch && keys.length > 0 && node.depth < limits.depth;
    const open = expandable && expanded.has(node.path);
    const text = branch ? `${array ? "[" : "{"} ${keys.length} ${array ? "items" : "keys"} ${array ? "]" : "}"}` : typeof node.value === "string" ? JSON.stringify(node.value) : String(node.value);
    rows.push({ path: node.path, key: node.key, depth: node.depth, expandable, open, type: node.value === null ? "null" : typeof node.value, text: text.length > limits.cell ? text.slice(0, limits.cell) + "…" : text });
    if (branch && keys.length && node.depth >= limits.depth) truncated = true;
    if (open) {
      // Bound the pending stack as well as the output; a huge flat object costs
      // at most the display budget even if every branch was previously expanded.
      const count = Math.min(keys.length, limits.rows - rows.length - stack.length);
      if (count < keys.length) truncated = true;
      for (let i = count - 1; i >= 0; i--) {
        const key = keys[i]; stack.push({ value: node.value[key], path: pointer(node.path, key), depth: node.depth + 1, key });
      }
    }
  }
  return { rows, truncated: truncated || stack.length > 0 };
}

export function delimiterOf(type, text) {
  if (type === "tsv") return "\t";
  let quoted = false, commas = 0, semicolons = 0;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '"') { if (quoted && text[i + 1] === '"') i++; else quoted = !quoted; }
    if (!quoted) { if (c === "\n" || c === "\r") break; if (c === ",") commas++; if (c === ";") semicolons++; }
  }
  return semicolons > commas ? ";" : ",";
}

export function parseDelimited(source, delimiter, limits = LIMITS) {
  const text = source.replace(/^\uFEFF/, ""), rows = [];
  let row = [], cell = "", mode = "start", ended = false, truncated = false;
  const endCell = () => {
    if (row.length < limits.columns) row.push(cell); else truncated = true;
    cell = ""; mode = "start";
  };
  const endRow = () => { endCell(); rows.push(row); row = []; ended = true; };
  for (let i = 0; i < text.length; i++) {
    const c = text[i]; ended = false;
    if (mode === "quoted") {
      if (c === '"' && text[i + 1] === '"') { cell += '"'; i++; }
      else if (c === '"') mode = "closed";
      else cell += c;
    } else if (c === delimiter) endCell();
    else if (c === "\n" || c === "\r") {
      if (c === "\r" && text[i + 1] === "\n") i++;
      endRow();
      if (rows.length === limits.rows && i + 1 < text.length) { truncated = true; break; }
    } else if (mode === "closed") throw new Error(`Unexpected text after a closing quote in row ${rows.length + 1}.`);
    else if (c === '"') {
      if (mode !== "start") throw new Error(`Unexpected quote in row ${rows.length + 1}.`);
      mode = "quoted";
    } else { cell += c; mode = "plain"; }
  }
  if (mode === "quoted") throw new Error(`Unclosed quoted field in row ${rows.length + 1}.`);
  if (!ended && text.length && rows.length < limits.rows) endRow();
  const count = rows.reduce((n, r) => Math.max(n, r.length), 0);
  const widths = Array.from({ length: count }, (_, i) => Math.min(320, Math.max(80, ...rows.slice(0, 200).map(r => Math.min((r[i] || "").length, 40) * 7 + 20))));
  return { rows, widths, truncated };
}

export function structuredPreview(type, text, truncated = false) {
  if (truncated) return { error: "This file is truncated. Use Source to inspect the available text." };
  try {
    if (type === "json") return { value: JSON.parse(text.replace(/^\uFEFF/, "")) };
    return parseDelimited(text, delimiterOf(type, text));
  } catch (error) { return { error: String(error.message || error) }; }
}
