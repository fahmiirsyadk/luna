---
title: Welcome to the Blog
date: 2026-04-06
slug: welcome
description: First post on the new Luna-powered blog
---

# Hello, World!

This is the first post on our new blog built with **Luna** - an Elm-like architecture for PureScript.

## Why Luna?

Luna provides a clean way to structure your frontend applications:

- **Type-safe routing** with `routing-duplex`
- **Hydration support** for fast initial page loads
- **PureScript** - no JavaScript required!

```purescript
data Route = Home | Post String | About

route :: RouteDuplex' Route
route = root $ sum
  { "Home": noArgs
  , "Post": "posts" / segment
  , "About": "about" / noArgs
  }
```

Stay tuned for more updates!
