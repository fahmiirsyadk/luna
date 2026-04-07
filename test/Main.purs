module Test.Main where

import Prelude

import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Exception (error, throwException)

import Luna.Html as H
import Luna.Html.Document as HD
import Luna.Html.Elements as HE
import Luna.Html.RenderString (renderHtmlString)
import Luna.Html.UnsafeHtml (unsafeRawHtml)
import Luna.Routing (ensureLeadingHash, stripLeadingHash)

main ∷ Effect Unit
main = do
  assertEqual "escape text amp" (renderHtmlString (H.text "a&b")) "a&amp;b"
  assertEqual "escape text lt" (renderHtmlString (H.text "a<b")) "a&lt;b"
  assertEqual "nested div" (renderHtmlString (HE.div [] [ H.text "hi" ])) "<div>hi</div>"
  assertEqual "script raw text (no entity escape)" (renderHtmlString (HE.script [] [ H.text "a<b" ])) "<script>a<b</script>"
  assertEqual "style raw text" (renderHtmlString (HE.style [] [ H.text "x" ])) "<style>x</style>"
  assertEqual "unsafe raw html" (renderHtmlString (unsafeRawHtml "<em>x</em>")) "<div class=\"luna-raw-html\"><em>x</em></div>"
  assertEqual "document body attrs"
    (HD.renderDocument $
      HD.emptyDocument
        # HD.withBodyAttrs [ Tuple "class" "app-root", Tuple "data-theme" "dark" ]
        # HD.withBodyHtml (HE.div [] [ H.text "ok" ])
    )
    "<!DOCTYPE html><html><head></head><body class=\"app-root\" data-theme=\"dark\"><div>ok</div></body></html>"
  assertEqual "routing stripLeadingHash" (stripLeadingHash "#/a") "/a"
  assertEqual "routing stripLeadingHash plain" (stripLeadingHash "x") "x"
  assertEqual "routing ensureLeadingHash" (ensureLeadingHash "p") "#p"
  assertEqual "routing ensureLeadingHash idempotent" (ensureLeadingHash "#q") "#q"

assertEqual ∷ String → String → String → Effect Unit
assertEqual label got want =
  when (got /= want) $
    throwException
      ( error
          $ label <> ":\n  got:  " <> show got <> "\n  want: " <> show want
      )
