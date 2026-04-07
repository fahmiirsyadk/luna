# Routing & State

Luna supports two routing approaches depending on your architecture:

1. **SPA routing** — For single-page apps where `App` manages route state
2. **Plain `<a href>` links** — For SSG sites where each page is a static HTML file

## Choose Your Approach


| Approach    | When to use                            | How                                       |
| ----------- | -------------------------------------- | ----------------------------------------- |
| SPA routing | Dashboards, admin panels, complex apps | `routing-duplex` + `pushState`/`popstate` |
| Plain links | Blogs, docs, marketing sites           | `<a href>` to pre-rendered pages          |


## SPA Routing

For single-page apps, use `routing-duplex` for type-safe route encoding/decoding and the browser History API for navigation.

### Define Routes

```purescript
module Routes where

import Prelude hiding ((/))
import Data.Either (hush)
import Data.Maybe (Maybe, fromMaybe)
import Data.String (Pattern(..), stripPrefix)
import Routing.Duplex (RouteDuplex', parse, print, root, segment)
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/))

data Route = Home | Post String | About

routeCodec :: RouteDuplex' Route
routeCodec =
  root $ sum
    { "Home": noArgs
    , "About": "about" / noArgs
    , "Post": "posts" / segment
    }

printRoute :: Route -> String
printRoute = print routeCodec

parseRoute :: String -> Maybe Route
parseRoute s = hush $ parse routeCodec path
  where
  path = fromMaybe s (stripPrefix (Pattern "#") s)
```

### Hash Routing

Use `routing-hash` for client-side hash-based routing:

```purescript
import Effect (Effect)
import Routing.Hash (matchesWith)

main :: Effect Unit
main = do
  inst <- PureApp.makeWithSelector app "#app"
  inst.run
  
  void $ matchesWith parseRoute \_old new ->
    inst.push (Navigate new) *> inst.run
```

### Path Routing with pushState

For path-based routing with browser history:

```purescript
import Effect (Effect)
import Web.HTML.History (History, pushState, replaceState)
import Web.HTML (window)
import Web.HTML.Window (history)

main :: Effect Unit
main = do
  inst <- PureApp.makeWithSelector app "#app"
  inst.run
  
  -- Subscribe to popstate (back/forward buttons)
  void $ matchesWith parseRoute \_old new ->
    inst.push (Navigate new) *> inst.run

-- From an action handler:
navigateTo :: Route -> Effect Unit
navigateTo route = do
  win <- window
  hist <- history win
  pushState hist Nothing "" (printRoute route)
  inst.push (Navigate route) *> inst.run
```

### Model Initialization from URL

```purescript
import Data.Maybe (fromMaybe)

main :: Effect Unit
main = do
  initialRoute <- getHash >>= pure <<< parseRoute
  let init = { route: fromMaybe Home initialRoute, posts: [] }
  
  inst <- PureApp.makeWithSelector (app { init }) "#app"
  inst.run
```

## Plain Links (SSG)

For SSG sites, each page is a pre-rendered HTML file. Use standard `<a href>` links:

```purescript
import Blog.Routes (printRoutePath)
import Blog.Types (Route(..))

-- NavBar component
navLink :: forall i. Route -> String -> Route -> Html i
navLink route label current =
  H.a
    [ H.href (printRoutePath route)
    , H.classes $ [ "nav-link" ] <> if current == route then [ "active" ] else []
    ]
    [ H.text label ]
```

No `Navigate` action, no routing subscriptions, no `pushState`. The browser handles everything.

### Generating hrefs with routing-duplex

Even for static sites, `routing-duplex` is useful at build time to generate correct URLs:

```purescript
-- Routes.purs — only printRoutePath is needed for SSG
printRoutePath :: Route -> String
printRoutePath = print routeCodec
```

Use it in your prerender step and in view functions to generate `<a href>` values.

## State Management

Update state based on actions using record syntax:

```purescript
update :: Model -> Action -> Model
update model = case _ of
  Navigate route -> 
    model { route = route }
  
  LoadPosts posts ->
    model { posts = posts }
  
  IncrementLikes postId ->
    model { posts = map updatePost model.posts }
    where
    updatePost post = if post.id == postId 
      then post { likes = post.likes + 1 }
      else post
```

## Subscriptions

For side effects, use the full `App` type:

```purescript
import Luna.App as App
import Luna.Interpreter (never)
import Luna.Batch (Batch, batch)

data TodoEffect a = Focus Element a

fullApp :: App TodoEffect (Const Void) Model Action
fullApp =
  { update: update
  , render: render
  , subs: subs
  , init: App.purely initialModel
  }

subs :: Model -> Batch TodoEffect Action
subs model = 
  batch 
    [ subscribeToWebSocket model
    , subscribeToHashChanges model
    ]
```

