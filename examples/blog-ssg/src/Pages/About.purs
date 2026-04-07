module Blog.Pages.About where

import Luna.Html as H
import Luna.Html (Html)

view :: forall i. Html i
view =
  H.div [ H.classes [ "about-view" ] ]
    [ H.h1 [] [ H.text "About" ]
    , H.p []
        [ H.text "This blog is built with Luna, an Elm-like architecture for PureScript." ]
    , H.p []
        [ H.text "It demonstrates SSG with hydration and type-safe routing." ]
    ]
