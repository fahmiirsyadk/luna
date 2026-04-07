module Blog.Types where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Show.Generic (genericShow)

type Post =
  { slug ∷ String
  , title ∷ String
  , date ∷ String
  , description ∷ String
  , bodyHtml ∷ String
  }

data Route
  = Home
  | Post String
  | About

derive instance eqRoute ∷ Eq Route
derive instance genericRoute ∷ Generic Route _

instance showRoute ∷ Show Route where
  show = genericShow

type LikeModel = { likes ∷ Int }

initialLikes ∷ LikeModel
initialLikes = { likes: 0 }
