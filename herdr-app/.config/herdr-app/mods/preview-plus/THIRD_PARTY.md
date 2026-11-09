# Third-party notices

These notices cover the named components, not the repository as a whole. Keep this file and `licenses/` with the installed renderer.

| Component | Version/source | License | Use and modifications |
| --- | --- | --- | --- |
| beautiful-mermaid | [1.1.3](https://github.com/lukilabs/beautiful-mermaid) | [MIT](licenses/beautiful-mermaid-MIT.txt) | Bundled SVG renderer, unmodified library source. |
| elkjs | [0.11.1](https://github.com/kieler/elkjs/tree/0.11.1) | [EPL-2.0](licenses/elkjs-EPL-2.0.txt) | Bundled layout engine; build-time patches support frozen prototypes, QuickJS globals and synchronous message dispatch. |
| entities | [7.0.1](https://github.com/fb55/entities/tree/v7.0.1) | [BSD-2-Clause](licenses/entities-BSD-2-Clause.txt) | Bundled entity decoding, unmodified. |
| Herdr Files Plus | [jjongkwann/herdr-files-plus](https://github.com/jjongkwann/herdr-files-plus/tree/b43c4e3e1dc2305c952ef923abda78abea095f70) | [MIT](licenses/Herdr-Files-Plus-MIT.txt) | `build/build.mjs` adapts its QuickJS patches. `mermaid.js` adapts its SVG color/font conversion and file caching; adds bounded input, diagram subset validation, in-flight sharing and theme/content cache identity. |
| Cria File Preview | [gsydler/cria-file-preview](https://github.com/gsydler/cria-file-preview/tree/62c2d220d1567988ea230a200197527febf02e20) | [Apache-2.0](licenses/Cria-APACHE-2.0.txt) | `structured.js` adapts JSON Pointer escaping and the pure JSON-row/quote-state parser approach from `json-tree.js` and `delimited.js`. Traversal, strict errors, limits and editable-source integration are changed. Its heading-from-section navigation is an API reference, not imported viewer code. |

The complete editable source for the modified elkjs component is the npm `elkjs@0.11.1` source package plus the explicit `ELK_PATCHES` in [`build/build.mjs`](../../build/build.mjs) in the Preview Plus distribution. Fetch the exact public npm packages with `npm ci` using [`package-lock.json`](../../package-lock.json), then run `npm run build`; no private registry or maintainer path is required. The patch build checks that every upstream replacement matches exactly once. The generated `mermaid.bundle.js` retains legal comments. esbuild 0.28.2 (MIT) is a build-only dependency and is not installed at runtime.

No browser, Node, Chromium, server or network call is used by the installed diagram renderer. Fonts come from the user's machine; generated SVGs have remote font imports and browser CSS variables/color mixing removed.
