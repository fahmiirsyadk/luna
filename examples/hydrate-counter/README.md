# Hydrate counter example

Same logic as the [counter example](../counter), but the page is **SSG’d**: a Node entry writes `index.html` with prerendered markup and an embedded initial model, then the browser bundle hydrates with `PureApp.makeHydrateWithSelector`.

## Shared code

- `[Ui.purs](src/Ui.purs)` — `Model`, `render`, `update`, and `initialModel` (default count shown in HTML and restored on the client).
- `[Main.purs](src/Main.purs)` — reads `window.__LUNA_INITIAL_MODEL__` via `deserializeModelWithDefault`, then `makeHydrateWithSelector` on `#app`.
- `[PrerenderMain.purs](src/PrerenderMain.purs)` — Node-only: builds a full document with `renderDocument`, `serializeModelScript`, and `withBodyHtml` (wrapping `render initial` in `<div id="app">…</div>`), writes `index.html` next to `app.js`.

Run from the **repository root** (paths are resolved from `process.cwd`):

```bash
pnpm run example:hydrate-counter
```

That runs `example:hydrate-counter:prerender` (`pnpm exec spago run` on `HydrateCounter.PrerenderMain`), then bundles `HydrateCounter.Main` to `app.js`. Open `index.html` in this directory.

## Alternative: hand-written HTML shell

If you maintain your own HTML template, merge prerendered body markup and the model script the same way as `PrerenderMain`: use `serializeModelScript` in the document head, ensure the client bundle matches the DOM you emitted, and point `deserializeModelWithDefault` at the same global variable name (default `__LUNA_INITIAL_MODEL__`).
