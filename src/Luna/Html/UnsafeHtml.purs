-- | Trusted HTML fragments (e.g. sanitized markdown). Do **not** pass unsanitized user input.
module Luna.Html.UnsafeHtml
  ( unsafeRawHtml
  ) where

import Luna.Html.Core (Html, elem, prop)
import Luna.Html.Properties (classes)

-- | Renders a string as HTML inside a wrapper `div.luna-raw-html` by setting the DOM
-- | `innerHTML` property. String output from `renderHtmlString` inlines the same markup
-- | (no entity escaping of the fragment).
-- |
-- | Hydration-safe: the VDOM has zero children while the SSG DOM has parsed HTML
-- | children from innerHTML. The VDOM hydrator skips child matching when the VDOM
-- | children array is empty, so the existing DOM content is preserved. The
-- | `innerHTML` property is re-applied via attribute hydration.
-- |
-- | **Security:** only use with content you fully control (your own markdown pipeline).
unsafeRawHtml :: forall i. String -> Html i
unsafeRawHtml html =
  elem "div"
    [ classes [ "luna-raw-html" ]
    , prop "innerHTML" html
    ]
    []
