// Reading a mod's settings, the same way in every mod.
//
// Source of truth: copied into each mod by `scripts/sync-shared` (see shared/llm.js for why).
//
// Settings come from three places, later ones winning:
//   1. the mod's built-in DEFAULTS;
//   2. `config/<mod>.json` in the app home (or in `$HERDR_MODS_CONFIG_DIR` when that variable is set);
//   3. `props.config` on the layout block that holds the mod, which scopes one copy.
// A file that is missing is fine. A file that is not valid JSON is reported and ignored.

/** Merge the three layers. `file` is the text of the config file or null; `props` is the block's props. */
export function mergeConfig(defaults, fileText, props) {
  let fromFile = {};
  let error = null;
  if (fileText && fileText.trim()) {
    try {
      const v = JSON.parse(fileText);
      if (v && typeof v === "object" && !Array.isArray(v)) fromFile = v;
      else error = "not a JSON object";
    } catch (e) {
      error = String(e);
    }
  }
  const scoped = props?.config && typeof props.config === "object" ? props.config : {};
  return { cfg: { ...defaults, ...fromFile, ...scoped }, error };
}

/** The path of a mod's config file. `override` is `$HERDR_MODS_CONFIG_DIR` (or null). */
export function configPath(appHome, name, override) {
  const dir = override && override.trim() ? override.trim().replace(/\/+$/, "") : `${appHome}/config`;
  return `${dir}/${name}.json`;
}
