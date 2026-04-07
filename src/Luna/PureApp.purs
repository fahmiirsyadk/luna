module Luna.PureApp
  ( PureApp
  , make
  , makeWithSelector
  , makeHydrate
  , makeHydrateWithSelector
  , toApp
  , module Luna.App
  ) where

import Prelude

import Effect (Effect)
import Luna.App (App, AppInstance, AppChange)
import Luna.App as App
import Luna.Html (Html)
import Luna.Interpreter (merge, never)
import Web.DOM.Node (Node)

-- | A `PureApp` has no effects or subscriptions.
type PureApp model action =
  { render ∷ model → Html action
  , update ∷ model → action → model
  , init ∷ model
  }

-- | Builds a running `PureApp`.
make
  ∷ ∀ model action
  . PureApp model action
  → Node
  → Effect (AppInstance model action)
make = App.make (never `merge` never) <<< toApp

-- | Builds a running `PureApp` given a DOM selector.
makeWithSelector
  ∷ ∀ model action
  . PureApp model action
  → String
  → Effect (AppInstance model action)
makeWithSelector = App.makeWithSelector (never `merge` never) <<< toApp

-- | Builds a `PureApp` that hydrates an existing rendered DOM tree.
-- | The selector should point to an element that already contains the
-- | rendered HTML from the server.
makeHydrate
  ∷ ∀ model action
  . PureApp model action
  → Node
  → Effect (AppInstance model action)
makeHydrate = App.makeHydrate (never `merge` never) <<< toApp

-- | Builds a `PureApp` that hydrates an existing rendered DOM tree
-- | given a DOM selector.
makeHydrateWithSelector
  ∷ ∀ model action
  . PureApp model action
  → String
  → Effect (AppInstance model action)
makeHydrateWithSelector = App.makeHydrateWithSelector (never `merge` never) <<< toApp

-- | Converts a `PureApp` to a regular `App`.
toApp
  ∷ ∀ model action void1 void2
  . PureApp model action
  → App void1 void2 model action
toApp app =
  { render: app.render
  , update: \model action → App.purely (app.update model action)
  , init: App.purely app.init
  , subs: mempty
  }
