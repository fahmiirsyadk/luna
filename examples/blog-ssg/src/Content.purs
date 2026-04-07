module Blog.Content where

import Prelude

import Blog.Types (Post)
import Data.Argonaut.Decode (decodeJson) as AD
import Data.Argonaut.Parser (jsonParser) as Parser
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Effect (Effect)
import Node.Encoding as Enc
import Node.FS.Sync as FS
import Node.Path (concat)
import Node.Process (cwd)

postsJsonPath :: Effect String
postsJsonPath = do
  projectRoot <- cwd
  pure $ concat [ projectRoot, "examples/blog-ssg/generated/posts.json" ]

readPosts :: Effect (Either String (Array Post))
readPosts = do
  jsonPath <- postsJsonPath
  content <- FS.readTextFile Enc.UTF8 jsonPath
  pure do
    json <- Parser.jsonParser content
    lmap (const "Failed to decode posts JSON") (AD.decodeJson json)
