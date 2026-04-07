# Unsafe coercion in Luna

Luna inherits patterns from Halogen’s virtual DOM and DOM layer. A few places use `unsafeCoerce` on purpose. They do **not** change runtime behavior of the DOM; they bridge PureScript’s type system to JavaScript APIs.

## `Luna.Html.Core`

- `**unwrapF` / `unwrapG`** — Coerces `Array (Html i)` to the internal `halogen-vdom` representation (`Array (VDom …)`). The representation is the same at runtime; the newtypes exist for API boundaries.
- `**on` event handlers** — Event listener types (`MouseEvent`, `KeyboardEvent`, …) are narrowed from the generic `Event` the browser provides. The coercion matches what Halogen’s prop layer expects.

## `Luna.Html.Events`

- `**unsafeCoerce` on events** — Same as Halogen: handlers are registered with a generic `Event` but user code may expect a more specific event type.

## When this matters

- You should still treat event APIs as **best-effort typing**: if the wrong handler is attached to the wrong element, runtime behavior is undefined, as in plain Halogen.
- Prefer `always_` / small decoders when you do not need the event object.

## Related

- `Luna.Html.UnsafeHtml` / `innerHTML` — Trusted HTML is set via properties; do not pass untrusted strings (see module docs).