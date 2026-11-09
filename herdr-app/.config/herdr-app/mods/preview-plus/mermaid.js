// SVG conversion/build adaptation from jjongkwann/herdr-files-plus (MIT).
// See licenses/Herdr-Files-Plus-MIT.txt and THIRD_PARTY.md.
import { appHome, readTextFile, writeTextFile } from "herdr";
import { mkdir } from "fs/promises";

// The renderer is large (about 1.5 MB of JavaScript), so it loads on the first diagram,
// not with the mod: most previews never need it.
let renderer = null;
const loadRenderer = async () => (renderer ??= (await import("./mermaid.bundle.js")).renderMermaidSVG);

// ---- CSS variables and color-mix() → concrete colors (the SVG loader understands neither).

function hex(c) {
  const m = /^#([0-9a-f]{3,8})$/i.exec(c.trim());
  if (!m) return null;
  let h = m[1];
  if (h.length === 3 || h.length === 4) h = [...h].map(x => x + x).join("");
  if (h.length !== 6 && h.length !== 8) return null;
  return [...[0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16)), h.length === 8 ? parseInt(h.slice(6), 16) : 255];
}
const toHex = rgb => "#" + rgb.map(v => Math.round(Math.max(0, Math.min(255, v))).toString(16).padStart(2, "0")).join("");

function args(s) {
  const out = [];
  let depth = 0, start = 0;
  for (let i = 0; i < s.length; i++) {
    if (s[i] === "(") depth++;
    else if (s[i] === ")") depth--;
    else if (s[i] === "," && depth === 0) { out.push(s.slice(start, i)); start = i + 1; }
  }
  out.push(s.slice(start));
  return out.map(a => a.trim());
}

function closing(s, open) {
  let depth = 0;
  for (let i = open; i < s.length; i++) {
    if (s[i] === "(") depth++;
    else if (s[i] === ")" && --depth === 0) return i;
  }
  return -1;
}

function evaluate(expr, vars, depth = 0) {
  expr = expr.trim();
  const fn = /^(var|color-mix)\(/.exec(expr);
  if (!fn || depth > 16) return expr;
  const end = closing(expr, fn[0].length - 1);
  const [first, ...rest] = args(expr.slice(fn[0].length, end));
  if (fn[1] === "var") {
    if (vars.has(first)) return vars.get(first);
    return rest.length ? evaluate(rest.join(","), vars, depth + 1) : "currentColor";
  }
  // color-mix(in srgb, A p%, B [q%])
  const stop = s => { const m = /^(.*?)(?:\s+([\d.]+)%)?$/.exec(s); return [evaluate(m[1], vars, depth + 1), m[2] === undefined ? null : +m[2]]; };
  const [[a, pa], [b, pb]] = rest.map(stop);
  const ca = hex(a ?? ""), cb = hex(b ?? "");
  if (!ca || !cb) return ca ? a : b;
  const p = pa ?? (pb === null ? 50 : 100 - pb);
  return toHex(ca.map((v, i) => (v * p + cb[i] * (100 - p)) / 100));
}

// Replaces every var()/color-mix() in a piece of CSS.
function resolve(css, vars) {
  let out = "", i = 0;
  for (;;) {
    const at = css.slice(i).search(/(var|color-mix)\(/);
    if (at < 0) return out + css.slice(i);
    const start = i + at, end = closing(css, css.indexOf("(", start));
    if (end < 0) return out + css.slice(i);
    out += css.slice(i, start) + evaluate(css.slice(start, end + 1), vars);
    i = end + 1;
  }
}

const STYLE = /<style>([\s\S]*?)<\/style>/g, ROOT = /^<svg\b[^>]*>/, ATTR = /(\s[\w:-]+=")([^"]*)(")/g;

/**
 * Rewrites the renderer's SVG so every color is literal and no remote font is fetched.
 * Only its <style> block and attribute values are touched; diagram text is left alone.
 */
export function flattenSvg(svg, font) {
  font = font.split(",").map(f => f.trim()).map(f => /^[\w-]+$/.test(f) ? f : `'${f.replace(/['"]/g, "")}'`).join(", ");
  // Variables come only from the root element's style and the <style> block, resolved once each, in order.
  const vars = new Map();
  const declarations = [ROOT.exec(svg)?.[0] ?? "", ...[...svg.matchAll(STYLE)].map(m => m[1])].join("\n");
  for (const m of declarations.matchAll(/(--[\w-]+)\s*:\s*([^;}"]+)/g))
    if (!vars.has(m[1])) vars.set(m[1], evaluate(resolve(m[2].trim(), vars), vars));
  const css = text => resolve(text, vars)
    .replace(/@import\s+url\([^)]*\)[^;]*;/g, "")
    .replace(/\s*--[\w-]+\s*:\s*[^;}"]+;?/g, "")
    .replace(/font-family\s*:\s*[^;}"]+/g, `font-family: ${font}`);
  return svg
    .replace(STYLE, (_, body) => `<style>${css(body)}</style>`)
    .replace(/<[a-zA-Z][^>]*>/g, tag => tag.replace(ATTR, (_, pre, value, post) =>
      pre.trim().startsWith("font-family=") ? `${pre}${font.replaceAll('"', "'")}${post}` : pre + css(value) + post));
}

// Bump when the SVG output changes: the image loader caches by path, so a new look needs a new name.
const RENDER_VERSION = 4;

function hash(s) {
  let h = 2166136261, other = 5381;
  for (let i = 0; i < s.length; i++) { h = Math.imul(h ^ s.charCodeAt(i), 16777619); other = Math.imul(other, 33) ^ s.charCodeAt(i); }
  return (h >>> 0).toString(36) + (other >>> 0).toString(36) + "-" + s.length;
}

/** Herdr theme → diagram colors. */
export function colorsFor(t) {
  return { bg: t.background, fg: t.foreground, line: t.dim, accent: t.ansi4, muted: t.muted, border: t.border };
}

/** The SVG loader resolves real family names and generic sans-serif, but not system-ui. */
export const FONT = "'Helvetica Neue', 'Segoe UI', Arial, 'Noto Sans', sans-serif";

/**
 * Renders one diagram into `<dir>/<hash>.svg` (dir relative to the app folder).
 * Returns { path, width, height } for image(), or throws with Mermaid's message.
 */
export async function renderToFile(source, { appHome, dir, colors, font = FONT, writeTextFile, readTextFile }) {
  const key = hash(JSON.stringify([RENDER_VERSION, source, colors, font]));
  const path = `${dir}/${key}.svg`, full = `${appHome}/${path}`;
  let svg = await readTextFile(full);
  if (svg === null) {
    const render = await loadRenderer();
    svg = flattenSvg(render(source, { ...colors, font, transparent: true }), font);
    await writeTextFile(full, svg, null).catch(async e => { if (await readTextFile(full) === null) throw e; });
  }
  const size = name => +(new RegExp(`<svg[^>]*\\s${name}="([\\d.]+)"`).exec(svg)?.[1] ?? 0);
  const width = size("width"), height = size("height");
  if (!(width > 0 && height > 0) || width > 32768 || height > 32768) throw new Error("Diagram dimensions exceed the native preview limit.");
  return { path, width, height };
}

const cache = new Map();
export async function diagram(source, look) {
  if (source.length > 24000 || source.split("\n").length > 300) throw new Error("Diagram is too large (24,000 characters or 300 lines).");
  const header = source.split("\n").map(line => line.trim()).find(line => line && !line.startsWith("%%")) || "";
  if (!/^(?:(?:graph|flowchart)\s+(?:TD|TB|BT|LR|RL)\b|sequenceDiagram\b|stateDiagram(?:-v2)?\b|classDiagram\b|erDiagram\b)/.test(header))
    throw new Error("Supported diagrams: flowchart, sequence, state, class and ER.");
  const colors = colorsFor(look.colors), font = look.font || FONT;
  const key = JSON.stringify([source, colors, font]);
  if (!cache.has(key)) {
    const pending = (async () => {
      const dir = "mods/preview-plus/.cache/diagrams";
      await mkdir(`${appHome()}/${dir}`, { recursive: true });
      return renderToFile(source, { appHome: appHome(), dir, colors, font, readTextFile, writeTextFile });
    })().catch(error => { cache.delete(key); throw error; });
    cache.set(key, pending);
    if (cache.size > 24) cache.delete(cache.keys().next().value);
  }
  return cache.get(key);
}
