module Luna.App
  ( App
  , AppInstance
  , AppChange
  , BasicApp
  , make
  , makeWithSelector
  , makeHydrate
  , makeHydrateWithSelector
  , module Luna.Batch
  , module Luna.Transition
  ) where

import Prelude

import Data.Const (Const)
import Data.Foldable (for_)
import Data.Functor.Coproduct (Coproduct, left, right)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Luna.Html.Core (Html, unHtml)
import Effect (Effect, foreachE)
import Effect.Exception (throwException, error)
import Effect.Ref as Ref
import Effect.Uncurried as EFn
import Halogen.VDom as V
import Halogen.VDom.DOM.Prop as P
import Halogen.VDom.Machine as Machine
import Halogen.VDom.Thunk (Thunk, buildThunk, hydrateThunk)
import Luna.Batch (Batch, batch, unBatch, lift)
import Luna.EventQueue (EventQueue, Loop(..))
import Luna.EventQueue as EventQueue
import Luna.Interpreter (Interpreter(..))
import Luna.Scheduler (makeImmediate)
import Luna.Transition (purely, Transition)
import Unsafe.Reference (unsafeRefEq)
import Web.DOM.Element (toNode) as DOMElement
import Web.DOM.Node (Node, appendChild, firstChild) as DOM
import Web.DOM.ParentNode (QuerySelector(..), querySelector) as DOM
import Web.HTML (window) as DOM
import Web.HTML.HTMLDocument (toDocument, toParentNode) as HTMLDocument
import Web.HTML.Window (document) as DOM

-- | A specification for a Luna app:
-- |    * `render` - Renders a model to `Html` which yields actions via DOM events.
-- |    * `update` - Takes the current model and, with a new action, transitions to a new model while optionally running effects.
-- |    * `subs` - Determines the set of active subscriptions based on the model.
-- |    * `init` - Initial model and effects to kickstart the application.
type App effects subs model action =
  { render ∷ model → Html action
  , update ∷ model → action → Transition effects model action
  , subs ∷ model → Batch subs action
  , init ∷ Transition effects model action
  }

-- | A type synonym for Apps which don't have subs.
type BasicApp effects model action = App effects (Const Void) model action

-- | The interface for communicating with a running App.
-- |    * `push` - Buffers an action to be run on the next tick.
-- |    * `run` - Initiates a tick of the App, flushing and applying all queued actions.
-- |    * `pushAndRun` - `push` then `run` so external callers do not forget to flush the queue.
-- |    * `snapshot` - Yields the current model of the App.
-- |    * `restore` - Replaces the current model of the App.
-- |    * `subscribe` - Listens to App changes (model and actions).
type AppInstance model action =
  { push ∷ action → Effect Unit
  , run ∷ Effect Unit
  , pushAndRun ∷ action → Effect Unit
  , snapshot ∷ Effect model
  , restore ∷ model → Effect Unit
  , subscribe ∷ (AppChange model action → Effect Unit) → Effect (Effect Unit)
  }

type AppChange model action =
  { old ∷ model
  , action ∷ action
  , new ∷ model
  }

data AppAction m q s i
  = Restore s
  | Action i
  | Interpret (Coproduct m q i)
  | Render

data RenderStatus
  = NoChange
  | Pending
  | Flushed

derive instance eqRenderStatus ∷ Eq RenderStatus

type AppState m q s i =
  { model ∷ s
  , status ∷ RenderStatus
  , interpret ∷ Loop Effect (Coproduct m q i)
  , vdom ∷ Machine.Step (V.VDom (Array (P.Prop i)) (Thunk Html i)) DOM.Node
  }

makeAppQueue
  ∷ ∀ m q s i
  . (AppChange s i → Effect Unit)
  → Interpreter Effect (Coproduct m q) i
  → App m q s i
  → DOM.Node
  → Maybe DOM.Node
  → EventQueue Effect (AppAction m q s i) (AppAction m q s i)
makeAppQueue onChange (Interpreter interpreter) app el hydrateStart = EventQueue.withAccum \self → do
  schedule ← makeImmediate (self.push Render *> self.run)
  let
    pushAction = self.push <<< Action
    pushEffect = self.push <<< Interpret <<< left

    nextStatus ∷ s → s → RenderStatus → RenderStatus
    nextStatus prevModel nextModel = case _ of
      NoChange
        | unsafeRefEq prevModel nextModel → NoChange
        | otherwise → Pending
      Flushed → NoChange
      Pending → Pending

    runSubs
      ∷ Loop Effect (Coproduct m q i)
      → Array (q i)
      → Effect (Loop Effect (Coproduct m q i))
    runSubs interpret subs = do
      ref ← Ref.new interpret
      foreachE subs \sub -> do
        Loop k _ ← Ref.read ref
        next ← k (right sub)
        Ref.write next ref
      Ref.read ref

    update
      ∷ AppState m q s i
      → AppAction m q s i
      → Effect (AppState m q s i)
    update state@{ interpret: Loop k _ } = case _ of
      Interpret m → do
        nextInterpret ← k m
        pure $ state { interpret = nextInterpret }
      Action i → do
        let
          next = app.update state.model i
          status = nextStatus state.model next.model state.status
          nextState = state { model = next.model, status = status }
          appChange = { old: state.model, action: i, new: next.model }
        onChange appChange
        foreachE (unBatch next.effects) pushEffect
        pure nextState
      Restore nextModel → do
        let
          status = nextStatus state.model nextModel state.status
          nextState = state { model = nextModel, status = status }
        pure nextState
      Render → do
        vdom ← EFn.runEffectFn2 Machine.step state.vdom (unHtml (app.render state.model))
        pure $ state { vdom = vdom, status = Flushed }

    commit
      ∷ AppState m q s i
      → Effect (AppState m q s i)
    commit state = case state.status of
      Flushed →
        pure $ state { status = NoChange }
      status → do
        when (status == Pending) schedule
        tickInterpret ← runSubs state.interpret (unBatch (app.subs state.model))
        nextInterpret ← case tickInterpret of Loop _ f → f unit
        pure $ state { interpret = nextInterpret, status = NoChange }

  document ←
    DOM.window
      >>= DOM.document
      >>> map HTMLDocument.toDocument
  let
    vdomSpec = V.VDomSpec
      { document
      , buildWidget: buildThunk unHtml
      , buildAttributes: P.buildProp (\a → pushAction a *> self.run)
      }
    hydrationSpec = V.VDomHydrationSpec
      { vdomSpec
      , hydrateWidget: hydrateThunk unHtml
      , hydrateAttributes: P.hydrateProp (\a → pushAction a *> self.run)
      }
  vdom <- case hydrateStart of
    Just node -> EFn.runEffectFn1 (V.hydrateVDom hydrationSpec node) (unHtml (app.render app.init.model))
    Nothing -> do
      built <- EFn.runEffectFn1 (V.buildVDom vdomSpec) (unHtml (app.render app.init.model))
      void $ DOM.appendChild (Machine.extract built) el
      pure built
  interpret ← interpreter (self { push = self.push <<< Action })
  foreachE (unBatch app.init.effects) pushEffect
  let
    init =
      { model: app.init.model
      , status: NoChange
      , interpret
      , vdom
      }
  pure { init, update, commit }

-- | Builds a running App given an `Interpreter` and a parent DOM Node.
-- |
-- | ```purescript
-- | example domNode = do
-- |   inst <- App.make (basicAff `merge` never) app domNode
-- |   _    <- inst.subscribe \_ -> log "Got a change!"
-- |   inst.run
-- | ```
-- |
-- | The returned `AppInstance` has yet to run any initial effects. You may
-- | use the opportunity to setup change handlers. Invoke `inst.run` when
-- | ready to run initial effects.
make
  ∷ ∀ effects subs model action
  . Interpreter Effect (Coproduct effects subs) action
  → App effects subs model action
  → DOM.Node
  → Effect (AppInstance model action)
make = makeWith Nothing

makeWith
  ∷ ∀ effects subs model action
  . Maybe DOM.Node
  → Interpreter Effect (Coproduct effects subs) action
  → App effects subs model action
  → DOM.Node
  → Effect (AppInstance model action)
makeWith hydrateStart interpreter app el = do
  subsRef ← Ref.new { fresh: 0, cbs: Map.empty }
  stateRef ← Ref.new app.init.model
  let
    handleChange ∷ AppChange model action → Effect Unit
    handleChange appChange = do
      Ref.write appChange.new stateRef
      subs ← Ref.read subsRef
      for_ subs.cbs (_ $ appChange)

    subscribe'
      ∷ (AppChange model action → Effect Unit)
      → (Effect (Effect Unit))
    subscribe' cb = do
      subs ← Ref.read subsRef
      subsRef # Ref.write
        { fresh: subs.fresh + 1
        , cbs: Map.insert subs.fresh cb subs.cbs
        }
      pure (remove subs.fresh)

    remove ∷ Int → Effect Unit
    remove key =
      subsRef # Ref.modify_ \subs → subs
        { cbs = Map.delete key subs.cbs
        }

  { push, run } ←
    EventQueue.fix $ makeAppQueue handleChange interpreter app el hydrateStart

  let
    pushAction = push <<< Action

  pure
    { push: pushAction
    , pushAndRun: \a → pushAction a *> run
    , snapshot: Ref.read stateRef
    , restore: push <<< Restore
    , subscribe: subscribe'
    , run
    }

-- | Builds a running App given an `Interpreter` and a DOM selector.
-- |
-- | ```purescript
-- | main = do
-- |   inst <- App.makeWithSelector (basicAff `merge` never) app "#app"
-- |   _    <- inst.subscribe \_ -> log "Got a change!"
-- |   inst.run
-- | ```
-- |
-- | The returned `AppInstance` has yet to run any initial effects. You may
-- | use the opportunity to setup change handlers. Invoke `inst.run` when
-- | ready to run initial effects.
makeWithSelector
  ∷ ∀ effects subs model action
  . Interpreter Effect (Coproduct effects subs) action
  → App effects subs model action
  → String
  → Effect (AppInstance model action)
makeWithSelector interpret app sel = do
  mbEl ←
    DOM.window
      >>= DOM.document
      >>> map HTMLDocument.toParentNode
      >>= DOM.querySelector (DOM.QuerySelector sel)
  case mbEl of
    Nothing → throwException (error ("Element does not exist: " <> sel))
    Just el → make interpret app (DOMElement.toNode el)

-- | Builds an App that hydrates an existing DOM tree. The DOM Node should
-- | contain the prerendered HTML that matches what the app would render.
makeHydrate
  ∷ ∀ effects subs model action
  . Interpreter Effect (Coproduct effects subs) action
  → App effects subs model action
  → DOM.Node
  → Effect (AppInstance model action)
makeHydrate interpreter app el = do
  mbFirst <- DOM.firstChild el
  makeWith mbFirst interpreter app el

-- | Builds an App that hydrates an existing DOM tree given a DOM selector.
makeHydrateWithSelector
  ∷ ∀ effects subs model action
  . Interpreter Effect (Coproduct effects subs) action
  → App effects subs model action
  → String
  → Effect (AppInstance model action)
makeHydrateWithSelector interpret app sel = do
  mbEl ←
    DOM.window
      >>= DOM.document
      >>> map HTMLDocument.toParentNode
      >>= DOM.querySelector (DOM.QuerySelector sel)
  case mbEl of
    Nothing → throwException (error ("Element does not exist: " <> sel))
    Just el -> makeHydrate interpret app (DOMElement.toNode el)
