module Luna.Html.Document
  ( DocumentBuilder
  , emptyDocument
  , withTitle
  , withMeta
  , withCharset
  , withHttpEquiv
  , withStylesheet
  , withInlineStyle
  , withScript
  , withScriptDefer
  , withScriptAsync
  , withScriptModule
  , withInlineScript
  , withBodyAttrs
  , withLang
  , withBodyHtml
  , withBodyHtmlString
  , withHeadExtra
  , renderDocument
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Luna.Html.Core (Html, attr)
import Luna.Html.Core as Core
import Luna.Html.RenderString (renderHtmlString) as Render

type DocumentBuilder =
  { head :: Array (Html Unit)
  , body :: Array (Html Unit)
  , bodyAttrs :: Array (Tuple String String)
  , lang :: Maybe String
  , title :: Maybe String
  }

emptyDocument :: DocumentBuilder
emptyDocument = { head: [], body: [], bodyAttrs: [], lang: Nothing, title: Nothing }

withTitle :: String -> DocumentBuilder -> DocumentBuilder
withTitle title doc = doc { title = Just title }

withMeta :: String -> String -> DocumentBuilder -> DocumentBuilder
withMeta name content doc = doc { head = doc.head <> [Core.elem "meta" [attr "name" name, attr "content" content] []] }

withCharset :: String -> DocumentBuilder -> DocumentBuilder
withCharset charset doc = doc { head = doc.head <> [Core.elem "meta" [attr "charset" charset] []] }

withHttpEquiv :: String -> String -> DocumentBuilder -> DocumentBuilder
withHttpEquiv equiv content doc = doc { head = doc.head <> [Core.elem "meta" [attr "http-equiv" equiv, attr "content" content] []] }

withStylesheet :: String -> DocumentBuilder -> DocumentBuilder
withStylesheet href doc = doc { head = doc.head <> [Core.elem "link" [attr "rel" "stylesheet", attr "href" href] []] }

withInlineStyle :: String -> DocumentBuilder -> DocumentBuilder
withInlineStyle css doc = doc { head = doc.head <> [Core.elem "style" [] [Core.text css]] }

withScript :: String -> DocumentBuilder -> DocumentBuilder
withScript src doc = doc { head = doc.head <> [Core.elem "script" [attr "src" src] []] }

withScriptDefer :: String -> DocumentBuilder -> DocumentBuilder
withScriptDefer src doc = doc { head = doc.head <> [Core.elem "script" [attr "src" src, attr "defer" "defer"] []] }

withScriptAsync :: String -> DocumentBuilder -> DocumentBuilder
withScriptAsync src doc = doc { head = doc.head <> [Core.elem "script" [attr "src" src, attr "async" "async"] []] }

withScriptModule :: String -> DocumentBuilder -> DocumentBuilder
withScriptModule src doc = doc { head = doc.head <> [Core.elem "script" [attr "src" src, attr "type" "module"] []] }

withInlineScript :: String -> DocumentBuilder -> DocumentBuilder
withInlineScript js doc = doc { head = doc.head <> [Core.elem "script" [] [Core.text js]] }

withBodyAttrs :: Array (Tuple String String) -> DocumentBuilder -> DocumentBuilder
withBodyAttrs attrs doc = doc { bodyAttrs = doc.bodyAttrs <> attrs }

withLang :: String -> DocumentBuilder -> DocumentBuilder
withLang lang doc = doc { lang = Just lang }

withBodyHtml :: Html Unit -> DocumentBuilder -> DocumentBuilder
withBodyHtml html doc = doc { body = [html] }

withBodyHtmlString :: String -> DocumentBuilder -> DocumentBuilder
withBodyHtmlString htmlStr doc = doc { body = [Core.text htmlStr] }

withHeadExtra :: Html Unit -> DocumentBuilder -> DocumentBuilder
withHeadExtra html doc = doc { head = doc.head <> [html] }

renderDocument :: DocumentBuilder -> String
renderDocument doc = 
  "<!DOCTYPE html>" <> 
  Render.renderHtmlString (Core.elem "html" (langAttr <> []) 
    [ Core.elem "head" [] (titleTag <> doc.head)
    , Core.elem "body" bodyAttrs doc.body
    ])
  where
  langAttr = case doc.lang of
    Nothing -> []
    Just l -> [attr "lang" l]
  bodyAttrs = map (\(Tuple key value) -> attr key value) doc.bodyAttrs
  titleTag = case doc.title of
    Nothing -> []
    Just t -> [Core.elem "title" [] [Core.text t]]