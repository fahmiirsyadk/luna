module HydrateCounter.Main where

import Prelude

import Effect (Effect)
import HydrateCounter.Ui (app)
import Luna.Html (deserializeModelWithDefault)
import Luna.PureApp as PureApp

main ∷ Effect Unit
main = do
  init <- deserializeModelWithDefault app.init
  void $
    PureApp.makeHydrateWithSelector
      (app { init = init })
      "#app"
