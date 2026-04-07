module Blog.Layouts.Site where

import Blog.Components.Footer (footer)
import Blog.Components.NavBar (navBar)
import Blog.Types (Route)
import Luna.Html as H
import Luna.Html (Html)

siteLayout :: forall i. Route -> Html i -> Html i
siteLayout current pageContent =
  H.div
    [ H.classes [ "app", "min-h-screen", "bg-zinc-950", "text-zinc-100", "antialiased" ] ]
    [ navBar current
    , H.main [ H.classes [ "main" ] ] [ pageContent ]
    , footer
    ]
