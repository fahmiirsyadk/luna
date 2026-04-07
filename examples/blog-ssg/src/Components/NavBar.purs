module Blog.Components.NavBar where

import Prelude

import Blog.Routes (printRoutePath)
import Blog.Types (Route(..))
import Luna.Html as H
import Luna.Html (Html)

navBar :: forall i. Route -> Html i
navBar current =
  H.nav
    [ H.classes [ "navbar" ] ]
    [ H.div [ H.classes [ "nav-brand" ] ]
        [ navLink Home "Luna Blog" current ]
    , H.ul [ H.classes [ "nav-links" ] ]
        [ navLink Home "Home" current
        , navLink About "About" current
        ]
    ]

navLink :: forall i. Route -> String -> Route -> Html i
navLink route label current =
  H.li [ H.classes [ "nav-item" ] ]
    [ H.a
        [ H.href (printRoutePath route)
        , H.classes $ [ "nav-link" ] <> if current == route then [ "active" ] else []
        ]
        [ H.text label ]
    ]
