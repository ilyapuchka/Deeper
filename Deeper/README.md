With `Deeper.Router` you register routes by registering handler closures which return spicific intent that should be performed when this deeplink is handeled or `nil` if it can't be properly handled. In this handler you have access to the full url, as well as to parsed parameters, extracted from the paths, based on the pattern that you are defining.

> Note: order of registration matters and defines priority of the route, first registered will be tried first when handling deeplink will happen.

```swift
let router = Router<Intent>(scheme: "myapp", rootDeepLinkHandler: appDelegate)

router.add(routes: ["profile/:userId") ]) { url, params in
	guard let userId = params[DeepLinkPatternParameter("userId")] else { return nil }
	return .showProfile(userId: userId)
}
```

You can use plain strings or make it more "type-safe" with a help of `DeepLinkPatternParameter` and some custom operators:

```swift

extension DeepLinkPatternParameter {
	static let userId = DeepLinkPatternParameter("userId")
}

router.add(routes: [ "profile" / .userId ]) { url, params in 
	guard let userId = params[.userId] else { return nil }
	return .showProfile(userId: userId)
}

```

You can do that not only for parameters but also for path components:

```swift

extension DeepLinkRoute {
	static let profile = DeepLinkRoute("profile")
}

router.add(routes: [ .profile / .userId ]) { url, params in 
	guard let userId = params[.userId] else { return nil }
	return .showProfile(userId: userId)
}

```

You can also use optional, conditional (this-or-that), wildcard or typed path components. Avoid very complex patterns because Swift can simply fail to compile them, but if you need you can use string format:

```swift
// match any number of paths before "profile"
route.add(routes: [ .any / .profile / .userId ]) { ... }
route.add(routes: [ "*/profile/:userId" ]) { ... }

// match "profile" or "user" path
route.add(routes: [ .profile | "user" / .userId ]) { ... }
route.add(routes: [ "(profile|user)/:userId" ]) { ... }

// match "profile/info/123" or just "profile/123"
route.add(routes: [ .profile /? "info" / .userId ]) { ... }
route.add(routes: [ "profile/(info)/:userId" ]) { ... }

// match "profile/123" but not "profile/abc"
route.add(routes: [ .profile / .int("userId") ]) { ... }
route.add(routes: [ "profile/:int(userId)" ]) { ... }
```

#### Query parameters

Along with path components you can match query parameters. Query parameters will be matched even if they appear in url in a different order then in a pattern. Url also can have any other parameters, they will be ignored during matching. Query parameters in a pattern are required unless they are explicitly marked as optional using `.maybe` or `.or` pattern.

```swift
// match `profile/userId=123&locale=us`
route.add(routes: [ .any / .profile .? .userId & .locale ]) { ... }
route.add(routes: [ "*/profile?:userId&:locale" ]) { ... }

// match `profile/userId=123&locale=us` and `profile/userId=123`
route.add(routes: [ .any / .profile .? .userId &? .locale ]) { ... }
route.add(routes: [ "*/profile?:userId&(:locale)" ]) { ... }
```

#### Custom operators

`/` - concatenates parts of path into a single route

`/?` - same as `/` but makes following path pattern optional (the same as using `.maybe` pattern)

`.?` - marks end of path pattern and start of query pattern, appends first query pattern to the route

`&` - appends following query pattern to the route, can only be used after applying `.?` or `.??`

`.??` / `&?` - the same as `.?` / `&` but makes following query pattern optional (the same as using `.maybe` pattern)

`|` - defines a pattern with two alternatives, either left or right pattern should match, left pattern will be checked first (the same as using `.or` pattern)
