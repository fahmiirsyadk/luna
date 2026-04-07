# Luna — Codebase Review

A fork of `purescript-spork` with added SSG/hydration capabilities. Elm-architecture (Model/Action/update/render) built on a forked `halogen-vdom` with hydration support. Package name: `luna`.

---

## Strengths

1. **Clean API surface** — `PureApp` for simple cases, full `App` for effects/subscriptions. The progression is intuitive.
2. **SSG/SSR story works** — `renderHtmlString` + `DocumentBuilder` + `serializeModelScript` / `deserializeModelWithDefault` form a complete prerender → hydrate pipeline.
3. **Good examples** — Counter, TodoMVC, hydrate-counter, and blog-ssg cover the spectrum from trivial to production-like.
4. **Type-safe HTML** — Uses `dom-indexed` for typed element properties (same approach as Halogen/Spork).
5. **Decent docs** — Guides cover the main workflows, including routing and unsafe-coercion notes.

---

## Pain Points — Status

### 1. Hydration is half-baked — DOCUMENTED (core gap remains)

The blog-ssg example does not hydrate the full tree because `unsafeRawHtml` uses `innerHTML`, which does not match a plain VDOM hydration walk.

**Done**: `docs/ssg.md` now has **Hydration and trusted HTML (`innerHTML`)** explaining when to use `makeHydrate` vs clear-and-mount.

**Remaining** (large): VDOM-level skip markers for raw-html subtrees, or similar, if full hydration with markdown is required.

### 2. ModelState serialization — FIXED

Typed `DecodeJson` + `Effect` API; see earlier implementation notes.

### 3. `withBodyAttrs` — FIXED

Implemented and tested.

### 4. Routing built in — FIXED

`Luna.Routing` + blog SPA navigation; hash helpers `stripLeadingHash` / `ensureLeadingHash` are exported and tested.

### 5. String rendering — `isRawTextElement` misleading — FIXED

Removed the always-`false` helper; child rendering now passes `false` explicitly with comments explaining that string serialization always escapes text (including inside `<script>` / `<style>`) for safety.

### 6. Heavy `unsafeCoerce` usage — DOCUMENTED

Added **[docs/unsafe-coercion.md](docs/unsafe-coercion.md)** describing Halogen-style coercion sites and when it matters.

### 7. No dev server / HMR story — PARTIALLY ADDRESSED

**Done**: Root `package.json` script `dev:blog` runs `serve` on `examples/blog-ssg/dist` (after you build the blog). Full HMR is still **OPEN**.

### 8. Tests — PARTIALLY ADDRESSED

Added tests for `withBodyAttrs`, routing hash helpers, plus existing `renderHtmlString` coverage. App lifecycle / hydration / scheduler tests remain **OPEN**.

### 9. Blog-ssg content pipeline is JavaScript — OPEN

`examples/blog-ssg/scripts/build-content.js` unchanged.

### 10. No error boundaries — OPEN

### 11. `AppInstance.push` requires manual `run` — FIXED

`**AppInstance`** now includes `**pushAndRun :: action -> Effect Unit`** (`push` then `run`). Docs (`docs/routing.md`) and README mention it.

### 12. Registry publishing — DEFERRED

---

## Features / Improvements — Status

### High Priority

1. **Real hydration with `innerHTML` regions** — OPEN (see above).
2. **Typed model serialization** — DONE.
3. **Routing integration module** — DONE.
4. **Publish to PureScript registry** — DEFERRED.

### Medium Priority

1. **Dev server with HMR** — OPEN (static `serve` only).
2. **Form helpers** — OPEN.
3. **Error boundary component** — OPEN.
4. **Better test coverage** — PARTIALLY DONE.
5. `**withBodyAttrs`** — DONE.
6. `**unsafeCoerce` audit** — DONE (documentation).

### Nice-to-Have

11–17 — Unchanged; still OPEN.

---

## Summary of Recent Fixes (this pass)


| Item           | Change                                                                                              |
| -------------- | --------------------------------------------------------------------------------------------------- |
| RenderString   | Removed misleading `isRawTextElement`; always escape child text with explicit `false` + comments    |
| `AppInstance`  | Added `pushAndRun`                                                                                  |
| `Luna.Routing` | Exported `stripLeadingHash`, `ensureLeadingHash`; tests                                             |
| Docs           | `docs/unsafe-coercion.md`; SSG hydration + `innerHTML` section; `docs/routing.md` uses `pushAndRun` |
| Tooling        | `pnpm dev:blog` in root `package.json`                                                              |
| README         | `pushAndRun`, `dev:blog`, link to unsafe-coercion doc                                               |
