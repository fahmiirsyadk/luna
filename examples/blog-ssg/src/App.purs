module Blog.App where

import Prelude

import Blog.Layouts.Site (siteLayout)
import Blog.Pages.About as AboutPage
import Blog.Pages.Home as HomePage
import Blog.Pages.Post as PostPage
import Blog.Types (Post, Route(..))
import Luna.Html (Html)

data Action
  = NoOp

update :: Action -> Action
update = identity

render :: Array Post -> Route -> Html Action
render posts route =
  siteLayout route $
    case route of
      Home -> HomePage.view posts
      About -> AboutPage.view
      Post slug -> PostPage.view slug posts
