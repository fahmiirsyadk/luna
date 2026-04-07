# Blog SSG + Island Hydration example

This example demonstrates building a blog with **Static Site Generation (SSG)** and **island hydration** using Luna.

## Features

- **SSG**: Every route is a fully pre-rendered HTML file (great for SEO and first paint)
- **Island hydration**: Only the "like" button on post pages is hydrated — nav, layout, and markdown body are pure static HTML with zero JS
- **Plain `<a href>` links**: No SPA router. Each page is a real file; navigation is browser-native
- **Tailwind CSS v4**: `styles/input.css` is compiled to `dist/styles.css` and linked per page
- **Type-safe route URLs**: `routing-duplex` codec used at build time to generate correct `<a href>` paths

## Architecture

```
Build Time (Node)          →  Output         →  Browser
────────────────────────────────────────────────────────────
content/posts/*.md          posts manifest   →  Static HTML pages
      ↓                                              ↓
markdown-it + yaml    →  JSON manifest    →  <a href> links (no JS)
      ↓                                              ↓
PrerenderMain         →  dist/*.html      →  Hydrate like button only
```

### Why not SPA navigation?

Every route already has a pre-rendered HTML file with the correct content. SPA navigation would:
- Lose data (post `bodyHtml` is only embedded on its own page)
- Walk the entire VDOM tree just to attach one click handler
- Add complexity (routing subscriptions, pushState, model sync)

Plain `<a href>` links are simpler, faster, and more resilient.

### What gets hydrated?

| Page | JavaScript? | What hydrates |
|------|-------------|---------------|
| `/` (home) | No | Nothing — pure static HTML |
| `/about` | No | Nothing — pure static HTML |
| `/posts/*` | Yes | Only `#like-button` — the like counter |

The inline JSON on post pages is tiny: `{"likes":0}`. No posts array, no `bodyHtml`, no route string.

## Folder Structure

```
examples/blog-ssg/
├── content/posts/       # Markdown content with YAML frontmatter
├── generated/          # Generated JSON manifest
├── scripts/            # Content pipeline (Node.js)
├── src/
│   ├── App.purs        # Static page render function (no SPA)
│   ├── Main.purs       # Client entry — hydrates #like-button only
│   ├── LikeButton.purs # Standalone PureApp for the like button
│   ├── PrerenderMain.purs  # Node entry for SSG
│   ├── Content.purs    # Generated content loading
│   ├── Routes.purs     # Duplex route codec (build-time href generation)
│   ├── Types.purs      # Types (Route, Post, LikeModel)
│   ├── Pages/          # Page modules (Home/About/Post)
│   ├── Components/     # Reusable UI pieces (NavBar, Footer, PostPreview)
│   ├── Layouts/        # Shared layout shell
│   └── Prerender/      # Prerender route/title declarations
├── styles/             # Tailwind v4 entry (input.css)
├── dist/               # Output HTML + JS + CSS
│   ├── index.html      # Home page (no JS)
│   ├── about/          # About page (no JS)
│   ├── posts/          # Blog posts (tiny JS for like button)
│   ├── styles.css      # Compiled Tailwind
│   └── app.js          # Client bundle (like button only)
├── spago.yaml
└── package.json
```

## Build

```bash
# Full build (content → prerender → bundle)
pnpm run example:blog-ssg

# Or step by step:
pnpm run example:blog-ssg:content   # Generate posts.json from markdown
pnpm run example:blog-ssg:prerender # Generate HTML
pnpm exec spago bundle -p example-blog-ssg    # Bundle JS
```

## Running

Serve `dist/` and open pages by path:
- `/` — Home (static, no JS)
- `/posts/welcome` — Blog post (like button hydrated)
- `/about` — About page (static, no JS)

## Key Concepts

### Island Hydration

Only the interactive region gets a hydration target:

```purescript
-- Post page renders a placeholder div with id "like-button"
H.div [ H.id_ "like-button" ]
  [ H.button [ H.classes [ "like-button" ] ]
      [ H.text "❤️ 0 likes" ]
  ]

-- Main.purs hydrates only that div
mbEl <- querySelector (QuerySelector "#like-button") ...
case mbEl of
  Just el -> do
    model <- deserializeModelWithDefault initialLikes
    inst <- PureApp.makeHydrate (app { init = model }) (toNode el)
    inst.run
  Nothing -> pure unit  -- no like button on this page
```

### Plain `<a href>` links

Navigation uses standard anchor tags — no onClick handlers, no SPA router:

```purescript
-- NavBar.purs
H.a [ H.href (printRoutePath route) ] [ H.text label ]

-- PostPreview.purs
H.a [ H.href (printRoutePath (Post p.slug)) ] [ H.text p.title ]
```

### Model Serialization

The inline model on post pages contains only interactive state:

```purescript
-- PrerenderMain.purs — post pages only
serializeModelScript $ toJsonString { likes: 0 }

-- Main.purs — reads it back
model <- deserializeModelWithDefault initialLikes
```

### Markdown Content

Post bodies are rendered with `unsafeRawHtml` (see `Pages/Post.purs`). Only use this for HTML produced by **your** markdown pipeline.

⚠️ **Security**: Never pass unsanitized user input to `unsafeRawHtml`.
