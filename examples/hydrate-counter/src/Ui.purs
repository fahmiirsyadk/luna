module HydrateCounter.Ui
  ( Model
  , Action(..)
  , update
  , render
  , app
  ) where

import Prelude

import Luna.Html (Html)
import Luna.Html as H
import Luna.PureApp (PureApp)

type Model = Int

data Action = Inc | Dec

update ∷ Model → Action → Model
update i = case _ of
  Inc → i + 1
  Dec → i - 1

render ∷ Model → Html Action
render i =
  H.div []
    [ H.button
        [ H.onClick (H.always_ Inc) ]
        [ H.text "+" ]
    , H.button
        [ H.onClick (H.always_ Dec) ]
        [ H.text "-" ]
    , H.span []
        [ H.text (show i)
        ]
    ]

-- | Default initial count (must match what `PrerenderMain` serializes into `index.html`).
initialModel ∷ Model
initialModel = 7

app ∷ PureApp Model Action
app = { update, render, init: initialModel }
