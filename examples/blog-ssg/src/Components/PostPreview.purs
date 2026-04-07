module Blog.Components.PostPreview where

import Blog.Routes (printRoutePath)
import Blog.Types (Post, Route(..))
import Luna.Html as H
import Luna.Html (Html)

postPreview :: forall i. Post -> Html i
postPreview p =
  H.li [ H.classes [ "post-preview" ] ]
    [ H.h2 [ H.classes [ "post-title" ] ]
        [ H.a
            [ H.href (printRoutePath (Post p.slug))
            , H.classes [ "post-link" ]
            ]
            [ H.text p.title ]
        ]
    , H.p [ H.classes [ "post-meta" ] ]
        [ H.text p.date ]
    , H.p [ H.classes [ "post-desc" ] ]
        [ H.text p.description ]
    ]
