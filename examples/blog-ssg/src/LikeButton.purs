module Blog.LikeButton where

import Prelude

import Blog.Types (LikeModel, initialLikes)
import Effect (Effect)
import Luna.Html (Html)
import Luna.Html as H
import Luna.Html.ModelState (deserializeModelWithDefault)
import Luna.PureApp (PureApp)

data Action
  = IncLike

update :: LikeModel -> Action -> LikeModel
update model = case _ of
  IncLike -> model { likes = model.likes + 1 }

render :: LikeModel -> Html Action
render model =
  H.button
    [ H.classes [ "like-button" ]
    , H.onClick (H.always_ IncLike)
    ]
    [ H.text $ "\x2764\xFE0F " <> show model.likes <> " likes" ]

app :: PureApp LikeModel Action
app =
  { render
  , update
  , init: initialLikes
  }

initFromModel :: Effect (PureApp LikeModel Action)
initFromModel = do
  model <- deserializeModelWithDefault initialLikes
  pure $ app { init = model }
