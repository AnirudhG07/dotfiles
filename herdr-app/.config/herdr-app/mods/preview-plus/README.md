# Preview Plus

Edit local text files and preview Markdown, JSON, CSV, TSV, images and PDFs inside Herdr. Markdown has a table of contents, heading links and native Mermaid diagrams. Save checks for external changes before writing and keeps unsaved drafts when a conflict occurs.

![Preview Plus running in Herdr](preview.png)

Preview Plus works without Files Plus. It can replace the standard single-folder Files panel, open a file through `pane.split` or `tab.new`, or receive selected files from [Files Plus](../files-plus/RECIPE.md).

See the [recipe](RECIPE.md) for behavior, dependencies and verification. The [implementation record](../docs/plans/preview-plus.md) contains the shared target contract and verification results.

## Install

Verified with Herdr 0.1.13 on macOS. Media uses built-in Foundation, AppKit and PDFKit through `osascript`. Linux images require `python3`; Windows images require Python 3 as `python`. Mermaid uses a bundled renderer and needs no Node.js or browser at runtime. No service credentials are required. The [recipe](RECIPE.md#built-from) lists the required Herdr APIs.

1. Check `${HERDR_APP_HOME:-$HOME/.config/herdr-app}/mods/preview-plus` for a name conflict. For an update, back up the installed files and compare local changes before replacing them. Use another name for an unrelated mod.
2. Copy `mods/preview-plus/`, including `mermaid.bundle.js`, `THIRD_PARTY.md` and its `licenses/`, into the app home's `mods/`. Do not copy `tests/`, `node_modules/`, generated type files or `.cache/`. Keep the package's existing `licenses/` with any redistribution too.
3. Run `herdr-app check <app-home>/mods/preview-plus`.
4. Use one of the three setups below. Clone a shipped layout with `herdr-app do layout.clone '{"name":"main","as":"my-preview"}'` before editing its structure. Preserve the surrounding Files/Changes block ids, sizes, visibility and shortcuts.

### Standalone Files panel

In a personal layout, change only the existing `files` block's content:

```json
{ "mod": "preview-plus" }
```

The focused terminal's folder appears as a lazy tree. Opening a file replaces the tree in place. Back walks followed links first, then restores the expanded tree.

### Pair with Files Plus

Files Plus sends every file type to Preview Plus. Its Tab and Pane destinations need no layout stack. To use Inside right panel, install [Files Plus](../files-plus/README.md) and replace the existing `files` block with this stack. Carry over the original block's layout sizing properties. Keep the outer `panel-body` stack and its `changes` child unchanged.

```json
{
  "id": "files",
  "type": "stack",
  "active": "files-plus-tree",
  "children": [
    {
      "id": "files-plus-tree",
      "type": "block",
      "content": { "mod": "files-plus", "props": { "previewStack": "files" } }
    },
    {
      "id": "preview-plus",
      "type": "block",
      "content": { "mod": "preview-plus", "props": { "previewStack": "files" } }
    }
  ]
}
```

Select Inside right panel in Files Plus settings to use this stack. Tab remains the default. Every file arrives as `{ file, root, on }`; Preview Plus chooses its editor, dedicated preview or unsupported-file message. Update both packages if an older Files Plus still opens ordinary text in its read-only viewer.

### Standalone pane or tab

Use an absolute file path; `root` defaults to the file's directory and `on` defaults to `null`:

```sh
herdr-app do pane.split '{"direction":"right","mod":"preview-plus","props":{"file":"/absolute/path/README.md"}}'
herdr-app do tab.new '{"name":"Document","mod":"preview-plus","props":{"file":"/absolute/path/guide.pdf"}}'
```

Pass `on` with the machine name for remote Markdown and text. Images and PDFs are local-only. PDF rendering is macOS-only; the Open control can launch a local PDF in its system application on other platforms.

## Edit and save

Ordinary local text opens in the native editor regardless of its extension. This includes code, configuration, hidden files and extensionless files. Markdown, JSON, CSV and TSV open in Preview; the code icon switches to Source, and the eye icon returns to Preview. Files Plus uses the same editor in Tab, Pane and paired panel mode.

The toolbar has Wrap lines, Save and Open controls with tooltips. Wrap lines is enabled in Source and disabled in Preview. A dot beside the filename marks unsaved changes. Save with the disk icon or, while the editor has focus, `Cmd+S` on macOS and `Ctrl+S` elsewhere. The mod adds no global shortcuts.

Wrap lines changes only the display. The preference is remembered. Herdr currently exposes wrapping and code appearance at editor creation only, so toggling wrap or changing the code theme or font rebuilds the editor. It preserves text, but selection, scroll position and undo history may reset. Native selection, copy/paste and undo/redo are otherwise provided by Herdr.

Unsaved drafts are retained when navigating and stored locally in Herdr's mod storage for recovery after remount/restart. They are removed after saving or confirmed discard; they are not uploaded. Discard appears only while a file has unsaved changes. Click its undo-arrow icon, then the check icon to confirm or the cross to cancel. File watching never overwrites a draft. If the disk contents have changed since loading, Save shows an error and keeps the draft. Copy any text you want to keep before confirming discard and reloading the disk version.

Editing is limited to complete local UTF-8 text. Remote files and previews truncated at 400,000 characters remain read-only; reads also have Herdr's 1 MiB limit. Images, PDFs and binary files are not editable. Draft recovery is best effort on a crash or forced termination, and a failed recovery-storage write is shown explicitly.

## Rich previews

Markdown's Contents icon shows top-level ATX and setext headings. `#heading` and `other.md#heading` open the document from that heading; Whole document returns to the full text. Back restores the previous heading, source mode and draft. Repeated headings receive `-1`, `-2`, etc.; Unicode headings and encoded fragments work. Headings inside fenced or indented code are excluded. The host cannot scroll ordinary Markdown programmatically, so earlier sections are hidden while a heading is selected. HTML/custom heading ids and headings nested in lists/quotes are not supported.

Top-level `mermaid` fences render flowcharts, sequence, state, class and ER diagrams through bundled beautiful-mermaid 1.1.3. This is its supported syntax subset, not the full Mermaid language; pie, gantt, mindmap, HTML labels and interactive diagram links are not offered. Invalid, unsupported, oversized or unclosed diagrams show an error with their source. Wide diagrams scroll horizontally to retain readable native text. Rendering is cached by source, diagram colors and font, including same-appearance theme changes. Limits are 24 diagrams per document, 24,000 characters/300 lines per diagram and 32,768 pixels per dimension. SVG cache eviction is manual alongside the existing media cache.

JSON starts with the root expanded; click a container row to expand/collapse it. CSV detects commas or semicolons outside quotes in the first record. TSV uses tabs. Quoted delimiters, escaped quotes, embedded newlines, CRLF and BOM are supported. The first table row is visually emphasized, and row numbers refer to records. Ragged rows retain all available cells. Invalid input explains the error and leaves Source available. Values/cells are read-only in Preview: it never serializes parsed JSON or rewrites CSV on Save. JSON numbers use JavaScript parsing semantics; Source retains their exact spelling.

Structured previews use virtual rows with a 10,000-row, 100-column and 64-level JSON depth limit. Displayed values are capped at 500 characters; wider cells and deeper indentation are clipped. These display limits never truncate an editable source. The existing 400,000-character text guard remains read-only. Remote structured files can be previewed but not saved.

## Development checks

Development fixtures require Node 22+; the installed mod does not use Node.

```sh
herdr-app check preview-plus/mods/preview-plus
node --experimental-vm-modules --test preview-plus/tests/*.test.mjs
node preview-plus/tests/check-mermaid.mjs
node preview-plus/tests/native-session.mjs
node preview-plus/tests/native-verify.mjs /tmp/pp.<session>/session.json
node preview-plus/tests/native-editor-verify.mjs /tmp/pp.<session>/session.json
node preview-plus/tests/native-rich-verify.mjs /tmp/pp.<session>/session.json
node preview-plus/tests/native-structured-pair.mjs /tmp/pp.<session>/session.json
```

Automated tests and isolated native checks cover rich previews, file handoff, editing and save conflicts on Herdr 0.1.13. Physical input and additional platform/theme combinations remain unverified for the latest changes. See the [all-file editor record](../docs/plans/preview-plus.md#all-file-editor-routing-2026-11-06) for the checked scope.

The native session command prints the exact receipt path. It starts a disposable app home and core, creates synthetic files and copies the runtime plus test drivers into that home. The verifier exercises production handlers and actual rendering; screenshots still require visual inspection. It does not change the user's app home, layout or key bindings. Close the disposable instance with `HERDR_APP_HOME=<receipt-app-home> herdr-app do app.quit`; its temporary core and files are scoped by the environment recorded in the receipt.

To reproduce the checked-in renderer from the public npm lock, use Node 22+:

```sh
cd preview-plus
npm ci --ignore-scripts
npm run build
npm run build -- --check
```

The build applies asserted QuickJS compatibility patches before bundling. `check-mermaid.mjs` executes five diagram families during initialization in a disposable `herdr-app check` root, without starting a core or a visible app session. It proves execution, not SVG painting. See [third-party notices](mods/preview-plus/THIRD_PARTY.md) for source, licenses and changes.
