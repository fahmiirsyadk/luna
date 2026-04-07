module Blog.PrerenderMain where

import Prelude

import Blog.App (render)
import Blog.Content (readPosts)
import Blog.Prerender.Pages as Pages
import Blog.Routes (printRoutePath)
import Blog.Types (LikeModel, Post, Route(..))
import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.String as String
import Effect (Effect)
import Effect.Console (log)
import Node.FS.Sync as FS
import Node.FS.Perms (permsAll)
import Node.Path (concat, dirname)
import Node.Process (cwd)
import Node.Encoding as Enc
import Data.Argonaut.Encode (toJsonString) as AE
import Luna.Html as H
import Luna.Html.Document
  ( emptyDocument
  , renderDocument
  , withBodyHtml
  , withCharset
  , withInlineScript
  , withScriptDefer
  , withStylesheet
  , withTitle
  )
import Luna.Html.ModelState (serializeModelScript)

toOutputFile :: Route -> String
toOutputFile route =
  case printRoutePath route of
    "/" -> "index.html"
    path -> stripLeadingSlash path <> "/index.html"
  where
  stripLeadingSlash p = case String.take 1 p of
    "/" -> String.drop 1 p
    _ -> p

relativeAssetPath :: String -> String -> String
relativeAssetPath assetName outputFile =
  relativePrefix depth <> assetName
  where
  segments = String.split (String.Pattern "/") outputFile
  depth = max 0 (Array.length segments - 1)
  relativePrefix n = String.joinWith "" (Array.replicate n "../")

ensureDir :: String -> Effect Unit
ensureDir path =
  FS.mkdir' path { recursive: true, mode: permsAll }

-- | Render a post page with like-button hydration.
-- | Embeds a tiny JSON model (just likes) and loads app.js.
renderPostPage :: String -> String -> Array Post -> Route -> String
renderPostPage title outputFile posts route =
  renderDocument $
    emptyDocument
      # withTitle title
      # withCharset "UTF-8"
      # withStylesheet stylesheetHref
      # withInlineScript (serializeModelScript $ AE.toJsonString initialLikes)
      # withBodyHtml bodyHtml
      # withScriptDefer scriptSrc
  where
  bodyHtml = void $ H.div [ H.id_ "app" ] [ render posts route ]
  scriptSrc = relativeAssetPath "app.js" outputFile
  stylesheetHref = relativeAssetPath "styles.css" outputFile
  initialLikes :: LikeModel
  initialLikes = { likes: 0 }

-- | Render a static page with zero JavaScript.
renderStaticPage :: String -> Array Post -> Route -> String
renderStaticPage title posts route =
  renderDocument $
    emptyDocument
      # withTitle title
      # withCharset "UTF-8"
      # withStylesheet stylesheetHref
      # withBodyHtml bodyHtml
  where
  bodyHtml = void $ H.div [ H.id_ "app" ] [ render posts route ]
  stylesheetHref = "../styles.css"

main :: Effect Unit
main = do
  projectRoot <- cwd
  let outDir = concat [ projectRoot, "examples/blog-ssg/dist" ]
  ensureDir outDir
  postsResult <- readPosts
  case postsResult of
    Left err -> log $ "Error reading posts: " <> err
    Right posts -> do
      for_ (Pages.allRoutes posts) \route -> do
        let outputFile = toOutputFile route
        let fullOutputFile = concat [ outDir, outputFile ]
        let parentDir = concat [ outDir, dirname outputFile ]
        ensureDir parentDir
        let doc = case route of
              Post _ ->
                renderPostPage (Pages.titleFor posts route) outputFile posts route
              _ ->
                renderStaticPage (Pages.titleFor posts route) posts route
        FS.writeTextFile Enc.UTF8 fullOutputFile doc

      log "Prerendered blog to dist/"
