module Blog.Prerender.Pages where

import Prelude

import Blog.Types (Post, Route(..))
import Data.Array (find)
import Data.Maybe (Maybe(..))

allRoutes :: Array Post -> Array Route
allRoutes posts =
  [ Home, About ] <> map (Post <<< _.slug) posts

titleFor :: Array Post -> Route -> String
titleFor posts = case _ of
  Home -> "Luna Blog"
  About -> "About - Luna Blog"
  Post slug -> case findTitle slug posts of
    Nothing -> "Post - Luna Blog"
    Just title -> title <> " - Luna Blog"

findTitle :: String -> Array Post -> Maybe String
findTitle slug posts =
  (_.title) <$> find (\post -> post.slug == slug) posts
