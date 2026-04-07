module Blog.Main where

import Prelude

import Blog.LikeButton (app)
import Blog.Types (initialLikes)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Luna.Html (deserializeModelWithDefault)

import Luna.PureApp as PureApp
import Web.DOM.Element (toNode) as DOMElement
import Web.DOM.ParentNode (QuerySelector(..), querySelector) as DOM
import Web.HTML (window)
import Web.HTML.HTMLDocument (toParentNode) as HTMLDocument
import Web.HTML.Window (document)

main ∷ Effect Unit
main = do
  mbEl <- window
    >>= document
    >>= \doc -> DOM.querySelector (DOM.QuerySelector "#like-button") (HTMLDocument.toParentNode doc)
  case mbEl of
    Nothing -> pure unit
    Just el -> do
      model <- deserializeModelWithDefault initialLikes
      inst <- PureApp.makeHydrate (app { init = model }) (DOMElement.toNode el)
      inst.run
