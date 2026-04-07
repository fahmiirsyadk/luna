# Getting Started

Luna is an Elm-like UI architecture for PureScript: `Model`, `Action`, `update`, and `render`.

## Installation

Add `spago` and `purescript` to `devDependencies` and run Spago only via **`pnpm exec spago`** or `pnpm` scripts—do not rely on a global Spago install.

Add Luna to your project's `spago.yaml`:

```yaml
package:
  name: my-app
  dependencies:
    - luna
    - prelude
    - effect
```

## Your First App

Create `src/Main.purs`:

```purescript
module Main where

import Prelude

import Effect (Effect)
import Luna.Html (Html)
import Luna.Html as H
import Luna.PureApp (PureApp)
import Luna.PureApp as PureApp

type Model = Int

data Action = Inc | Dec

update :: Model -> Action -> Model
update i = case _ of
  Inc -> i + 1
  Dec -> i - 1

render :: Model -> Html Action
render i =
  H.div []
    [ H.button
        [ H.onClick (H.always_ Inc) ]
        [ H.text "+" ]
    , H.button
        [ H.onClick (H.always_ Dec) ]
        [ H.text "-" ]
    , H.span []
        [ H.text (show i) ]
    ]

app :: PureApp Model Action
app = { update, render, init: 0 }

main :: Effect Unit
main = void $ PureApp.makeWithSelector app "#app"
```

Create `index.html` with a mount node:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>My App</title>
</head>
<body>
  <div id="app"></div>
  <script src="app.js"></script>
</body>
</html>
```

## Build & Bundle

Use Spago from your project’s `package.json` (never a global install):

```bash
pnpm exec spago build
pnpm exec spago bundle --platform browser --bundle-type app --module Main --outfile app.js
```

Open `index.html` in your browser to see the counter.

## Key Patterns

### Event handlers

Use `H.always_` when you don't need the event data:

```purescript
H.button [ H.onClick (H.always_ Inc) ] [ H.text "+" ]
```

Use `H.always` when wrapping an action constructor:

```purescript
H.input [ H.onValueInput (H.always UpdatePending) ] []
```

### Keep app parts separate

Keep `update`, `render`, and `app` as separate top-level definitions:

```purescript
update :: Model -> Action -> Model
update model action = ...

render :: Model -> Html Action
render model = ...

app :: PureApp Model Action
app = { update, render, init: initialModel }
```

### Use lazy rendering for expensive views

Use `H.lazy` and `H.lazy2` for expensive subtrees:

```purescript
render model =
  H.div []
    [ H.lazy renderInput model.pending
    , H.lazy2 renderTodos model.visibility model.todos
    ]
```

## Next Steps

- [Pages & Rendering](pages.md) - Build HTML views
- [Routing & State](routing.md) - Sync routes and app state
- [Hydration & SSG](ssg.md) - Prerender and mount/hydrate on client

