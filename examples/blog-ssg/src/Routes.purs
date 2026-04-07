module Blog.Routes where

import Prelude hiding ((/))

import Blog.Types (Route)
import Routing.Duplex (RouteDuplex', print, root, segment)
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/))

routeCodec :: RouteDuplex' Route
routeCodec =
  root $ sum
    { "Home": noArgs
    , "About": "about" / noArgs
    , "Post": "posts" / segment
    }

printRoutePath :: Route -> String
printRoutePath = print routeCodec
