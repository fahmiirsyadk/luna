# Pages & Rendering

Luna uses a virtual DOM approach inspired by Halogen. Create type-safe HTML with the `Html` type.

## Basic Elements

```purescript
import Luna.Html as H
import Luna.Html.Elements as HE

view :: Html Action
view = 
  H.div [ H.id_ "app", H.classes ["container"] ]
    [ HE.h1 [] [ H.text "Hello World" ]
    , HE.p [] [ H.text "Welcome to Luna" ]
    , HE.button [ H.onClick (H.always_ MyAction) ] [ H.text "Click Me" ]
    ]
```

## Properties

Common properties for elements:

```purescript
myElement :: Html Action
myElement = 
  H.div 
    [ H.id_ "my-id"
    , H.classes ["class1", "class2"]
    , H.style "display: flex"
    , H.hidden false
    , H.title "Tooltip text"
    ]
    [ H.text "Content" ]
```

## Events

Handle user interactions with `H.always_` for simple actions:

```purescript
-- Simple: always emit same action
H.button [ H.onClick (H.always_ HandleClick) ] [ H.text "Click me" ]

-- With event data: use the handler directly
H.input 
  [ H.onValueInput handler ] 
  []

handler :: String -> Maybe Action
handler value = Just (UpdateText value)

-- Key events
onEnter :: Action -> H.IProp (onKeyDown :: Event.KeyboardEvent | r) Action
onEnter action = H.onKeyDown \ev ->
  if Event.key ev == "Enter" then Just action else Nothing
```

## Conditional & List Rendering

```purescript
import Data.Array as Array

showItems :: Array Item -> Html Action
showItems items = 
  H.ul [] (map renderItem items)

renderItem :: Item -> Html Action  
renderItem item =
  H.li [ H.key (show item.id) ] [ H.text item.name ]

-- Conditional
showLoggedIn :: Boolean -> Html Action
showLoggedIn isLoggedIn =
  H.div [] 
    [ if isLoggedIn 
        then H.text "Welcome back!" 
        else H.text "Please log in"
    ]
```

## Lazy Rendering

Avoid unnecessary re-renders:

```purescript
-- Lazy: only re-renders when data changes
render :: Model -> Html Action
render model =
  H.div []
    [ H.lazy renderInput model.pending
    , H.lazy2 renderTodos model.visibility model.todos
    ]

renderInput :: String -> Html Action
renderInput = ...

renderTodos :: Visibility -> Array Todo -> Html Action
renderTodos = ...

-- Memoized: uses custom equality
memoView :: Data -> Html Action  
memoView data =
  H.memoized eqData renderData data
```

## String Rendering

Render HTML to string for SSR/SSG:

```purescript
import Luna.Html.RenderString (renderHtmlString)
import Luna.Html (Html)

htmlToString :: Html Unit -> String
htmlToString html = renderHtmlString html
```

Note: Only `Html Unit` can be rendered to strings. Use `map (\_ -> unit)` to convert.

## Keyed Lists

For lists that may reorder, use keyed rendering:

```purescript
import Data.Tuple (Tuple(..))

renderKeyedTodos :: Array Todo -> Html Action
renderKeyedTodos todos =
  H.ul []
    (map renderKeyedTodo todos)

renderKeyedTodo :: Todo -> Tuple String (Html Action)
renderKeyedTodo todo =
  Tuple (show todo.id) (renderTodo todo)
```

Then in your view:

```purescript
import Luna.Html.Elements.Keyed as K

K.ul [ H.classes ["todo-list"] ]
  (map renderKeyedTodo todos)
```

## Trusted HTML (`unsafeRawHtml`)

Render sanitized HTML fragments (e.g. from a markdown pipeline):

```purescript
import Luna.Html (unsafeRawHtml)

markdownView :: String -> Html Action
markdownView sanitizedHtml =
  H.div [ H.classes [ "markdown-body" ] ]
    [ unsafeRawHtml sanitizedHtml ]
```

**Warning:** Only use `unsafeRawHtml` with content you fully control. Never pass unsanitized user input. See [unsafe-coercion.md](unsafe-coercion.md) for details.
