-- | Node entry: writes `index.html` for the hydrate-counter example using the same
-- | `render` / `init` as the browser bundle (SSG). Run from the repo root:
-- | `pnpm run example:hydrate-counter:prerender` or `spago run -p example-hydrate-counter --main HydrateCounter.PrerenderMain`.
module HydrateCounter.PrerenderMain where

import Prelude

import Effect (Effect)
import Node.FS.Sync as FS
import Node.Encoding (Encoding(..))
import Node.Process as Process

import HydrateCounter.Ui (app, render)
import Luna.Html as H
import Luna.Html
  ( serializeModelScript
  , renderDocument
  , emptyDocument
  , withTitle
  , withCharset
  , withBodyHtml
  , withScript
  , withInlineScript
  )

main ∷ Effect Unit
main = do
  cwd ← Process.cwd
  let
    outPath = cwd <> "/examples/hydrate-counter/index.html"
    initial = app.init
    doc =
      renderDocument $
        emptyDocument
          # withTitle "Luna hydrate counter"
          # withCharset "UTF-8"
          # withInlineScript (serializeModelScript (show initial))
          # withBodyHtml (H.div [ H.id_ "app" ] [ map (\_ -> unit) (render initial) ])
          # withScript "app.js"
  FS.writeTextFile UTF8 outPath doc
