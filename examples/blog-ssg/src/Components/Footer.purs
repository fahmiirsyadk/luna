module Blog.Components.Footer where

import Luna.Html as H
import Luna.Html (Html)

footer :: forall i. Html i
footer =
  H.footer [ H.classes [ "footer" ] ]
    [ H.p [] [ H.text "Built with Luna ❤️" ] ]
