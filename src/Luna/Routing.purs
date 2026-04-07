module Luna.Routing
  ( RoutingMode(..)
  , NavigationMethod(..)
  , RouteCodec
  , stripLeadingHash
  , ensureLeadingHash
  , currentPath
  , currentHash
  , currentRouteString
  , decodeCurrentRoute
  , navigateTo
  , navigate
  , subscribeRouteChanges
  , subscribeDecodedRouteChanges
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), stripPrefix)
import Effect (Effect)
import Foreign (unsafeToForeign)
import Web.Event.Event (EventType(..))
import Web.Event.EventTarget (EventListener, addEventListener, eventListener, removeEventListener)
import Web.HTML (window)
import Web.HTML.History (DocumentTitle(..), URL(..), pushState, replaceState)
import Web.HTML.Location as Location
import Web.HTML.Window (toEventTarget)
import Web.HTML.Window as Window

data RoutingMode
  = HashRouting
  | PathRouting

data NavigationMethod
  = Push
  | Replace

type RouteCodec route =
  { parse :: String -> Maybe route
  , print :: route -> String
  }

currentPath :: Effect String
currentPath = do
  w <- window
  loc <- Window.location w
  Location.pathname loc

currentHash :: Effect String
currentHash = do
  w <- window
  loc <- Window.location w
  hash <- Location.hash loc
  pure (stripLeadingHash hash)

currentRouteString :: RoutingMode -> Effect String
currentRouteString = case _ of
  HashRouting -> currentHash
  PathRouting -> currentPath

decodeCurrentRoute :: forall route. RouteCodec route -> RoutingMode -> Effect (Maybe route)
decodeCurrentRoute codec mode = map codec.parse (currentRouteString mode)

navigateTo :: RoutingMode -> NavigationMethod -> String -> Effect Unit
navigateTo mode method target = do
  w <- window
  case mode of
    HashRouting -> do
      loc <- Window.location w
      Location.setHash (ensureLeadingHash target) loc
    PathRouting -> do
      history <- Window.history w
      let
        title = DocumentTitle ""
        url = URL target
        state = unsafeToForeign unit
      case method of
        Push -> pushState state title url history
        Replace -> replaceState state title url history

navigate :: forall route. RouteCodec route -> RoutingMode -> NavigationMethod -> route -> Effect Unit
navigate codec mode method route =
  navigateTo mode method (codec.print route)

subscribeRouteChanges :: RoutingMode -> Effect Unit -> Effect (Effect Unit)
subscribeRouteChanges mode onChange = do
  w <- window
  listener <- mkRouteListener onChange
  let
    target = toEventTarget w
    eventType = routeEventType mode
  addEventListener eventType listener false target
  pure (removeEventListener eventType listener false target)

subscribeDecodedRouteChanges
  :: forall route
   . RouteCodec route
  -> RoutingMode
  -> (Maybe route -> Effect Unit)
  -> Effect (Effect Unit)
subscribeDecodedRouteChanges codec mode onRoute =
  subscribeRouteChanges mode do
    route <- decodeCurrentRoute codec mode
    onRoute route

mkRouteListener :: Effect Unit -> Effect EventListener
mkRouteListener onChange = eventListener \_ -> onChange

routeEventType :: RoutingMode -> EventType
routeEventType = case _ of
  HashRouting -> EventType "hashchange"
  PathRouting -> EventType "popstate"

stripLeadingHash :: String -> String
stripLeadingHash str = case stripPrefix (Pattern "#") str of
  Just rest -> rest
  Nothing -> str

ensureLeadingHash :: String -> String
ensureLeadingHash str = case stripPrefix (Pattern "#") str of
  Just _ -> str
  Nothing -> "#" <> str
