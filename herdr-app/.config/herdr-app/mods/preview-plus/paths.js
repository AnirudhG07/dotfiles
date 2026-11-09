const IMAGES = new Set(["png", "jpg", "jpeg", "webp", "svg"]);

export function normalize(path) {
  const windows = /^[a-z]:[\\/]|^\\\\/i.test(path);
  const source = windows ? path.replaceAll("\\", "/") : path;
  const prefix = source.startsWith("//") ? "//" : source.startsWith("/") ? "/" : /^[a-z]:\//i.test(source) ? source.slice(0, 3) : "";
  const parts = [];
  for (const part of source.slice(prefix.length).split("/")) {
    if (!part || part === ".") continue;
    if (part === ".." && parts.length && parts.at(-1) !== "..") parts.pop();
    else if (part !== ".." || !prefix) parts.push(part);
  }
  return prefix + parts.join("/") || ".";
}

export const absolute = path => /^(?:\/|[a-z]:[\\/]|\\\\)/i.test(path);
export const basename = path => normalize(path).split("/").pop() || path;
export function dirname(path) {
  const value = normalize(path), index = value.lastIndexOf("/");
  return index === 0 ? "/" : index === 2 && value[1] === ":" ? value.slice(0, 3) : index < 0 ? "." : value.slice(0, index);
}
export const join = (base, path) => normalize(absolute(path) ? path : `${base}/${path}`);
export const extension = path => basename(path).split(".").pop().toLowerCase();
export const kind = path => IMAGES.has(extension(path)) ? "image" : ["pdf", "json", "csv", "tsv"].includes(extension(path)) ? extension(path) : ["md", "markdown"].includes(extension(path)) ? "markdown" : "text";
export const richText = type => ["markdown", "json", "csv", "tsv"].includes(type);

export function target(value) {
  if (!value || typeof value.file !== "string" || !absolute(value.file)) return null;
  if (value.on != null && typeof value.on !== "string") return null;
  const file = normalize(value.file);
  return { file, root: typeof value.root === "string" && absolute(value.root) ? normalize(value.root) : dirname(file), on: value.on || null };
}

export function resolveLink(file, href) {
  const link = href.trim().replace(/\\([\\`*{}\[\]()#+.!_> -])/g, "$1");
  if (/^https?:\/\//i.test(link)) return { url: link };
  if (link.startsWith("//")) return { url: `https:${link}` };
  let anchor;
  if (link.includes("#")) {
    try { anchor = decodeURIComponent(link.slice(link.indexOf("#") + 1)); }
    catch { throw new Error("This link contains an invalid heading anchor."); }
  }
  if (!link || link.startsWith("#")) return { anchor: anchor || "" };
  if (/^[a-z][a-z\d+.-]*:/i.test(link) && !/^[a-z]:[\\/]/i.test(link) && !link.startsWith("file:///")) throw new Error("This link type cannot be opened here.");
  let path = link.replace(/[?#].*$/, "").replace(/^file:\/\//, "");
  try { path = decodeURIComponent(path); } catch { throw new Error("This link contains an invalid file path."); }
  return { file: join(dirname(file), path), ...(anchor !== undefined ? { anchor } : {}) };
}

export function imageSize(width, height, viewport, zoom) {
  const scale = zoom === null ? Math.min(Math.max(1, viewport.width - 32) / width, Math.max(1, viewport.height - 32) / height) : zoom;
  return { width: Math.max(1, width * scale), height: Math.max(1, height * scale) };
}
