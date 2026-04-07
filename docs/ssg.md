# Hydration & Static Site Generation (SSG)

Luna supports two complementary patterns: **full hydration** for SPAs and **island hydration** for SSG sites where most content is static HTML.

## Mental Model

**SSG means each page is a complete HTML file.** The HTML is the source of truth for content. JavaScript only touches the interactive parts.

```
Prerendered HTML  =  content (nav, layout, markdown, links)
Inline JSON       =  interactive state only (likes, counters, form state)
Client JS         =  hydrates only the interactive islands
```

## Pattern 1: Full Hydration (SPA)

The entire page is a single Luna app. Use `makeHydrate` or `makeHydrateWithSelector` when the whole DOM was prerendered and you want to attach interactivity everywhere.

```purescript
import Effect (Effect)
import Luna.PureApp as PureApp
import Luna.Html (deserializeModelWithDefault)

main :: Effect Unit
main = do
  model <- deserializeModelWithDefault defaultModel
  inst <- PureApp.makeHydrateWithSelector (app { init = model }) "#app"
  inst.run
```

Best for pages where most elements are interactive (dashboards, admin panels, complex forms).

## Pattern 2: Island Hydration (SSG Blog)

Only specific regions get hydrated. The rest of the page is pure static HTML with `<a href>` links.

```
Page structure:
┌─────────────────────────────────┐
│  Navbar (static <a> links)      │  ← zero JS
├─────────────────────────────────┤
│  Article title (static)         │  ← zero JS
│  Date (static)                  │  ← zero JS
│  Markdown body (unsafeRawHtml)  │  ← zero JS
├─────────────────────────────────┤
│  <div id="like-button">         │  ← hydrated island
│    ❤️ 42 likes                  │
│  </div>                         │
└─────────────────────────────────┘
```

### How it works

**1. Prerender** — Generate HTML with a placeholder for the interactive region:

```purescript
-- PrerenderMain.purs
renderPostPage :: String -> Array Post -> Route -> String
renderPostPage title posts route =
  renderDocument $
    emptyDocument
      # withTitle title
      # withCharset "UTF-8"
      # withInlineScript (serializeModelScript (toJsonString { likes: 0 }))
      # withBodyHtml bodyHtml
      # withScriptDefer "app.js"
  where
  bodyHtml = void $ H.div [ H.id_ "app" ] [ render posts route ]
```

The post view renders a static placeholder for the like button:

```purescript
-- Pages/Post.purs
H.div [ H.id_ "like-button" ]
  [ H.button [ H.classes [ "like-button" ] ]
      [ H.text "❤️ 0 likes" ]
  ]
```

**2. Hydrate only the island** — The client finds the island and hydrates it:

```purescript
-- Main.purs
main :: Effect Unit
main = do
  mbEl <- querySelector (QuerySelector "#like-button") documentNode
  case mbEl of
    Nothing -> pure unit  -- no interactive content on this page
    Just el -> do
      model <- deserializeModelWithDefault { likes: 0 }
      inst <- PureApp.makeHydrate likeButtonApp (toNode el)
      inst.run
```

**3. Navigation is plain `<a href>`** — No SPA router needed:

```purescript
-- NavBar.purs — standard anchor tags
H.a [ H.href (printRoutePath route) ] [ H.text label ]

-- PostPreview.purs
H.a [ H.href (printRoutePath (Post p.slug)) ] [ H.text p.title ]
```

Each page is a real file. The browser handles navigation natively.

## When to use which pattern


| Scenario                   | Pattern              | Why                                                       |
| -------------------------- | -------------------- | --------------------------------------------------------- |
| Blog, docs, marketing site | Island hydration     | Most content is static; only small parts are interactive  |
| Dashboard, admin panel     | Full hydration       | Most elements are interactive; SPA navigation makes sense |
| Counter, TodoMVC           | Full hydration (SPA) | Single-page app, no prerendering needed                   |


## Build Pipeline

```bash
# 1. Generate content (markdown -> JSON)
pnpm run example:blog-ssg:content

# 2. Prerender pages (Node.js)
pnpm run example:blog-ssg:prerender

# 3. Bundle client JavaScript
pnpm run example:blog-ssg:bundle
```

## Project Structure (SSG Blog)

```
my-app/
├── spago.yaml
├── src/
│   ├── Main.purs            # Client entry — hydrates islands
│   ├── LikeButton.purs      # Standalone PureApp for the like button
│   ├── PrerenderMain.purs  # Server entry (generates HTML)
│   ├── App.purs            # Static page render function
│   ├── Routes.purs          # Duplex codec (build-time href generation)
│   ├── Types.purs           # Types (Route, Post, LikeModel)
│   ├── Pages/               # Page modules
│   └── Components/          # Reusable UI pieces
├── content/
│   └── posts/               # Markdown content
├── generated/
│   └── posts.json           # Compiled content
└── dist/
    ├── index.html           # Home page (no JS)
    ├── about/
    │   └── index.html       # About page (no JS)
    ├── posts/
    │   └── hello/
    │       └── index.html   # Post page (tiny JS for like button)
    └── app.js               # Client bundle (islands only)
```

## Model State Functions

```purescript
import Luna.Html.ModelState

-- Variable name for embedded model (default: "__LUNA_INITIAL_MODEL__")
defaultModelVariable :: String

-- Generate script tag: "window.__LUNA_INITIAL_MODEL__=..."
serializeModelScript :: String -> String

-- Decode model from window (for hydration)
deserializeModel :: forall a. DecodeJson a => Effect (Either String a)

-- Read with fallback default
deserializeModelWithDefault :: forall a. DecodeJson a => a -> Effect a
```

## Important Notes

1. **Match exactly**: Hydration requires the prerendered HTML to exactly match what `render` produces for the hydrated region
2. **Keep islands small**: Only put interactive elements in hydrated regions. Static content stays as plain HTML
3. **Embed model before script**: The `serializeModelScript` must run before your client JS loads
4. **Two entry points**: Separate `Main.purs` (browser) and `PrerenderMain.purs` (Node)
5. **Use `<a href>` for navigation**: In SSG mode, each page is a real file. Plain links are simpler and more resilient than SPA routing

## Hydration and trusted HTML (`innerHTML`)

VDOM hydration compares the prerendered DOM to what `render` would produce. Markup set via `unsafeRawHtml` uses `innerHTML` on a wrapper node, so **that subtree is not a simple text/element vdom match**.

- For pages **without** trusted HTML fragments, use `PureApp.makeHydrate` / `makeHydrateWithSelector` (see `examples/hydrate-counter`).
- For **markdown or other trusted HTML** inlined in the view, use **island hydration**: keep the markdown outside the hydrated region, and only hydrate the interactive parts (like buttons, comment forms, etc.). See `examples/blog-ssg`.

## Example: Blog SSG

See `examples/blog-ssg/` for a complete implementation with:

- Markdown content pipeline
- Multiple page types (home, post, about)
- Island hydration (only the like button)
- Plain `<a href>` navigation between pages

