# Build Pipeline & Extension

Configure and extend Luna for your project.

## Building Your App

```bash
# Build
pnpm exec spago build

# Bundle for browser
pnpm exec spago bundle --platform browser --bundle-type app --module Main --outfile app.js
```

Add to `package.json` (with `spago` in `devDependencies`):

```json
{
  "scripts": {
    "build": "pnpm exec spago build && pnpm exec spago bundle --platform browser --bundle-type app --module Main --outfile app.js",
    "dev": "pnpm exec spago build && esbuild app.js --bundle --outfile=dist/bundle.js --watch"
  }
}
```

## Development Workflow

1. Write your PureScript code in `src/`
2. Build with `pnpm exec spago build`
3. Bundle with `pnpm exec spago bundle ...`
4. Open `index.html` in browser

## Project Setup

Create `spago.yaml` for your project:

```yaml
package:
  name: my-app
  dependencies:
    - luna
    - prelude
    - effect
    - routing-hash
    - argonaut-codecs

workspace:
  packageSet:
    registry: 75.7.0
  extraPackages:
    luna:
      git: https://github.com/your-org/luna.git
      ref: main
```

## Document Builder

The `DocumentBuilder` supports chaining for SSG:

```purescript
import Luna.Html.Document
  ( renderDocument, emptyDocument
  , withTitle, withCharset, withBodyHtml, withHeadExtra, withScript )

myDocument :: String
myDocument = 
  renderDocument $
    emptyDocument
      # withTitle "My Page"
      # withCharset "UTF-8"
      # withStylesheet "style.css"
      # withScript "app.js"
      # withHeadExtra customHead
      # withBodyHtml bodyContent
```

## Common Configurations

### Simple SPA

```yaml
package:
  name: my-spa
  dependencies:
    - luna
    - prelude
    - effect
    - routing-hash
```

### SSG Blog

```yaml
package:
  name: my-blog
  dependencies:
    - luna
    - prelude
    - effect
    - routing-duplex
    - argonaut-codecs
    - argonaut-parser
    - node-fs
    - node-path
    - node-process
```

## Output

After build:

- `output/` - Compiled PureScript modules (in `.spago/output/`)
- Your bundle `app.js` - Browser JavaScript

After prerender (SSG):

- `dist/` - HTML files with embedded state

## SSG Build Pipeline

For a static site, the build has three phases:

```
1. Content generation    →  JSON manifest (markdown → HTML)
2. Prerender (Node.js)   →  HTML files per route
3. Bundle (browser)      →  app.js for interactive islands
```

Example:

```bash
# 1. Generate content
node scripts/build-content.js

# 2. Prerender all pages
pnpm exec spago run -p my-blog --main PrerenderMain

# 3. Bundle client JS
pnpm exec spago bundle -p my-blog --platform browser --bundle-type app --module Main --outfile dist/app.js
```

The prerender step (`PrerenderMain`) runs in Node.js and generates one HTML file per route. For SSG sites, only pages with interactive elements need a `<script>` tag pointing to `app.js`.

## Customizing

Luna is designed to be extended. Common extensions:

### Custom Elements

Use `H.elem` directly:

```purescript
customElement :: Html Action
customElement = H.elem "my-element" [] [ H.text "content" ]
```

### Custom Properties

Use `H.prop`:

```purescript
customProp :: IProp (data-custom :: String | r) Action
customProp = H.prop "data-custom"
```

### Custom Events

Use `H.on`:

```purescript
onCustomEvent :: (CustomData -> Maybe Action) -> IProp r Action
onCustomEvent handler = H.on "custom-event" \ev ->
  handler (decodeCustomData ev)
```
