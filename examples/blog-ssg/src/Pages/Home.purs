module Blog.Pages.Home where

import Prelude

import Blog.Components.PostPreview (postPreview)
import Blog.Types (Post)
import Data.Array as Array
import Luna.Html as H
import Luna.Html (Html)

view :: forall i. Array Post -> Html i
view posts =
  H.div [ H.classes [ "home-view" ] ]
    [ H.h1 [] [ H.text "Latest Posts" ]
    , if Array.null posts then
        H.p [ H.classes [ "no-posts" ] ] [ H.text "No posts yet." ]
      else
        H.ul [ H.classes [ "post-list" ] ]
          (map postPreview posts)
    ]
