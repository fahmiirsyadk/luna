# Luna

Luna is an Elm-like library for purescript, heavy inspired from spork and halogen

> this is modified of spork and halogen-vdom hydration fork. ideally i wanted sweet spot to gain small footprint.
> highly experimental, lots of things are not implemented yet and still hardcoded.

## Installation
Luna is **not** published on Pursuit / the package registry. You consume it directly from Git and pin versions via `spago.yaml`.

### Add Luna from Git

In your project's `spago.yaml`, add Luna under `extraPackages` pointing at this repository:

```yaml
workspace:
  extraPackages:
    luna:
      git: https://github.com/fahmiirsyadk/luna.git 
      ref: 37ae92731e68b701ac04de4418e56a0bdbf6f572
```

Then list `luna` in your package’s `dependencies`:

```yaml
package:
  name: your-app
  dependencies:
    - luna
    # …
```

After that you can run your local scripts (e.g. `pnpm build`) and import `Luna.Html`, `Luna.PureApp`, etc. as usual.

Add Spago as a dev dependency and run it only through **`pnpm`**:

```json
{
  "devDependencies": {
    "purescript": "0.15.15",
    "spago": "^1.0.4"
  },
  "scripts": {
    "build": "pnpm exec spago build",
    "test": "pnpm exec spago test"
  }
}
```

From a shell you can also run `pnpm exec spago build` without adding scripts.

## Example

```purescript
module Main where

import Prelude
import Effect (Effect)
import Luna.Html as H
import Luna.PureApp (PureApp)
import Luna.PureApp as PureApp

type Model = Int
data Action = Inc

update :: Model -> Action -> Model
update i = case _ of
  Inc -> i + 1

render :: Model -> H.Html Action
render i =
  H.button [ H.onClick (H.always_ Inc) ] [ H.text ("Count: " <> show i) ]

app :: PureApp Model Action
app = { init: 0, update, render }

main :: Effect Unit
main = void $ PureApp.makeWithSelector app "#app"
```

## Main Features

- `PureApp` and `App` APIs for pure or effectful architecture
- `Luna.Html` typed HTML + events
- SSG primitives (`renderHtmlString`, document builder, model serialization)
- Hydration and SPA URL helpers via `Luna.Routing`

SSG + client model restore:

```purescript
import Luna.Html (deserializeModelWithDefault)
import Luna.Html.ModelState (serializeModelScript)

-- prerender:
script = serializeModelScript modelJson

-- browser:
init <- deserializeModelWithDefault defaultModel
```

## Deployment

Build browser output:

```bash
pnpm build
pnpm exec spago bundle --platform browser --bundle-type app --module Main --outfile dist/app.js
```

Then deploy your static files (`index.html`, `dist/app.js`, CSS/assets) to any static host.

After building `examples/blog-ssg`, you can preview its `dist/` locally:

```bash
pnpm dev:blog
```

## Documentation

- [Getting started](docs/getting-started.md)
- [Pages & rendering](docs/pages.md)
- [Routing & state](docs/routing.md)
- [Hydration & SSG](docs/ssg.md)
- [Build pipeline](docs/build-pipeline.md)
- [Unsafe coercion (Halogen-style)](docs/unsafe-coercion.md)

## Examples

- [examples/counter](examples/counter) - Minimal `PureApp` counter
- [examples/subs](examples/subs) - Subscriptions / interpreter pattern
- [examples/todo-mvc](examples/todo-mvc) - TodoMVC-style SPA
- [examples/hydrate-counter](examples/hydrate-counter) - SSG + embedded model + client hydration
- [examples/blog-ssg](examples/blog-ssg) - Markdown -> JSON -> prerendered HTML + island hydration (like button only)

## License

MIT