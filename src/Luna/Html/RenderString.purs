module Luna.Html.RenderString where

import Prelude

import Data.Array (filter, head, drop, null) as A
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), Replacement(..))
import Data.String.Common (replaceAll)
import Data.Tuple (Tuple(..))
import Luna.Html.Core (Html, unHtml)
import Halogen.VDom as V
import Halogen.VDom.DOM.Prop (Prop(..))
import Halogen.VDom.Thunk (runThunk)
import Halogen.VDom.Types (ElemName(..), runGraft)
import Halogen.VDom.Util as VUtil

renderHtmlString :: forall html. Html html -> String
renderHtmlString root = go false (unHtml root)
  where
  go inRawText vdom = case vdom of
    V.Text s -> if inRawText then s else escapeText s
    V.Elem _ (ElemName name) attrs children ->
      case extractInnerHtml attrs of
        Just raw
          | A.null children ->
              "<" <> name <> renderProps (withoutInnerHtml attrs) <> ">" <> raw <> "</" <> name <> ">"
        _ ->
          "<" <> name <> renderProps attrs <> ">"
            <> renderChildren (rawTextElement name) children
            <> "</" <> name <> ">"
    V.Keyed _ (ElemName name) attrs children ->
      case extractInnerHtml attrs of
        Just raw
          | A.null children ->
              "<" <> name <> renderProps (withoutInnerHtml attrs) <> ">" <> raw <> "</" <> name <> ">"
        _ ->
          "<" <> name <> renderProps attrs <> ">"
            <> renderKeyedChildren (rawTextElement name) children
            <> "</" <> name <> ">"
    V.Widget thunk -> go inRawText (unHtml (runThunk thunk))
    V.Grafted g -> go inRawText (runGraft g)

  renderChildren inRawText arr = case A.head arr of
    Nothing -> ""
    Just x -> go inRawText x <> renderChildren inRawText (A.drop 1 arr)

  renderKeyedChildren inRawText arr = case A.head arr of
    Nothing -> ""
    Just (Tuple _ x) -> go inRawText x <> renderKeyedChildren inRawText (A.drop 1 arr)

  renderProps arr = case A.head arr of
    Nothing -> ""
    Just p -> renderProp p <> renderProps (A.drop 1 arr)

  renderProp = case _ of
    Attribute _ key value ->
      " " <> key <> "=\"" <> escapeAttr value <> "\""
    Property key value
      | VUtil.unsafeIsBooleanFalse value -> ""
      | otherwise ->
          let attrName = propertyToAttributeName key
              attrValue = VUtil.unsafeString value
          in
            " " <> attrName <> "=\"" <> escapeAttr attrValue <> "\""
    Handler _ _ -> ""
    Ref _ -> ""

  propertyToAttributeName = case _ of
    "className" -> "class"
    "htmlFor" -> "for"
    "httpEquiv" -> "http-equiv"
    "acceptCharset" -> "accept-charset"
    key -> key

  extractInnerHtml :: forall i. Array (Prop i) -> Maybe String
  extractInnerHtml props =
    case A.head props of
      Nothing -> Nothing
      Just p -> case p of
        Property "innerHTML" v
          | not (VUtil.unsafeIsBooleanFalse v) -> Just (VUtil.unsafeString v)
        _ -> extractInnerHtml (A.drop 1 props)

  withoutInnerHtml :: forall ix. Array (Prop ix) -> Array (Prop ix)
  withoutInnerHtml = A.filter \p -> case p of
    Property "innerHTML" _ -> false
    _ -> true

  -- | `<script>` and `<style>` contents are raw text (not HTML-escaped). Escaping `<` to
  -- | `&lt;` breaks embedded JSON (e.g. `window.__LUNA_INITIAL_MODEL__`) and causes
  -- | hydration mismatches for `innerHTML` props that mirror that data.
  -- | If you embed untrusted strings in a script, escape at the JSON layer (e.g. `\u003c`).
  rawTextElement :: String -> Boolean
  rawTextElement = case _ of
    "script" -> true
    "style" -> true
    _ -> false

  escapeText s =
    replaceAll (Pattern "&") (Replacement "&amp;") s
      # replaceAll (Pattern "<") (Replacement "&lt;")
      # replaceAll (Pattern ">") (Replacement "&gt;")

  escapeAttr s =
    replaceAll (Pattern "&") (Replacement "&amp;") s
      # replaceAll (Pattern "<") (Replacement "&lt;")
      # replaceAll (Pattern "\"") (Replacement "&quot;")