module Blog.Pages.Post where

import Prelude

import Blog.Types (Post)
import Data.Array as Array
import Data.Maybe (Maybe(..))
import Luna.Html as H
import Luna.Html (Html, unsafeRawHtml)

view :: forall i. String -> Array Post -> Html i
view slug posts =
  case Array.find (_.slug >>> (==) slug) posts of
    Nothing ->
      H.div [ H.classes [ "post-view" ] ]
        [ H.h1 [] [ H.text "Post not found" ] ]
    Just p ->
      H.article [ H.classes [ "post-view" ] ]
        [ H.h1 [ H.classes [ "post-title" ] ] [ H.text p.title ]
        , H.div [ H.classes [ "post-meta" ] ]
            [ H.text p.date ]
        , H.div [ H.classes [ "post-body" ] ] [ unsafeRawHtml p.bodyHtml ]
        , H.div [ H.classes [ "post-footer" ] ]
            [ H.div [ H.id_ "like-button" ]
                [ H.button
                    [ H.classes [ "like-button" ]
                    ]
                    [ H.text $ "\x2764\xFE0F 0 likes" ]
                ]
            ]
        ]
