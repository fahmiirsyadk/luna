module Luna.Html.ModelState
  ( defaultModelVariable
  , serializeModelScript
  , serializeModelScriptFrom
  , deserializeModel
  , deserializeModelWithDefault
  ) where

import Prelude

import Data.Argonaut.Core (Json, stringify)
import Data.Argonaut.Decode (class DecodeJson, decodeJson)
import Data.Argonaut.Encode.Class (class EncodeJson, encodeJson)
import Data.Either (Either(..))
import Effect (Effect)

defaultModelVariable :: String
defaultModelVariable = "__LUNA_INITIAL_MODEL__"

serializeModelScript :: String -> String
serializeModelScript model = "window." <> defaultModelVariable <> "=" <> model <> ";"

-- | Slice (or otherwise transform) once, then encode once for the inline script so prerender and client cannot drift.
serializeModelScriptFrom :: forall a. EncodeJson a => (a -> a) -> a -> String
serializeModelScriptFrom f a = serializeModelScript (stringify (encodeJson (f a)))

foreign import hasWindowModel :: Effect Boolean
foreign import getWindowModelJson :: Effect Json

deserializeModel :: forall a. DecodeJson a => Effect (Either String a)
deserializeModel = do
  hasModel <- hasWindowModel
  if not hasModel then
    pure (Left ("Missing window." <> defaultModelVariable))
  else do
    modelJson <- getWindowModelJson
    pure (mapLeft show (decodeJson modelJson))
  where
  mapLeft f = case _ of
    Left e -> Left (f e)
    Right x -> Right x

deserializeModelWithDefault :: forall a. DecodeJson a => a -> Effect a
deserializeModelWithDefault fallback = do
  parsed <- deserializeModel
  pure $ case parsed of
    Left _ -> fallback
    Right model -> model