With `DeeperFunc.Router` your register routes by associating your intent cases (or any other constructor) with url patterns.

```swift
let router = Router<Intent>(scheme: "myapp", rootDeepLinkHandler: appDelegate)

router.add(Intent.showProfile, route: "profile" /> string )
```

You will also need to make your intent type conform to `Route` protocol. For that you need to implement `Equatable` protocol and `deconstruct` function:

```swift
extension Intent: Route {

  func deconstruct<A>(_ constructor: ((A) -> Intent)) -> A? {
  	switch self {
  	  case let .showProfile(values as A) where self == constructor(values): return values
  	  case let .follow(values as A) where self == constructor(values): return values
  	  case let .retweet(values as A) where self == constructor(values): return values
  	}
  } 

}
```

As you can see this is just a boilerplate. You can generate it with Sourcery as well as `Equatable` conformance.

You can also use optional, conditional (this-or-that), wildcard or typed path components. Avoid very complex patterns because Swift can simply fail to compile them, but if you need you can use string format:

```swift
// match any number of paths before "profile"
route.add(..., route: any /> "profile" / string)
route.add(..., format: "*/profile/:string")

// match "profile" or "user" path
route.add(..., route: ("profile" | "user") /> string)
route.add(..., format: "(profile|user)/:string")

// match "profile/info/123" or just "profile/123"
route.add(..., route: "profile" /? "info" /> string)
route.add(..., format: "profile/(info)/:string)

// match "profile/123" but not "profile/abc"
route.add(..., route: "profile" /> int)
route.add(..., format: "profile/:int")
```

#### Query parameters

Along with path components you can match query parameters. Query parameters will be matched even if they appear in url in a different order then in a pattern. Url also can have any other parameters, they will be ignored during matching. Query parameters in a pattern are required unless they are explicitly marked as optional.

```swift
// match `profile/userId=123&locale=us`
route.add(..., route: any /> "profile" .? int("userId") & string("locale") ])
route.add(..., format: "*/profile?userId=:int&locale=:string" ])

// match `profile/userId=123&locale=us` and `profile/userId=123`
route.add(..., route: any /> "profile" .? int("userId") &? string("locale") ])
route.add(..., format: "*/profile?userId=:userId&(locale=:string)" ])
```

#### Custom operators

`/>`, `>/>` - concatenates parts of path into a single route

`/?` - same as `/>` or `>/>` but makes following path pattern optional

`.?` - marks end of path pattern and start of query pattern, appends first query pattern to the route

`&` - appends following query pattern to the route, can only be used after applying `.?` or `.??`

`.??` / `&?` - the same as `.?` / `&` but makes following query pattern optional

`|` - defines a pattern with two alternatives, either left or right pattern should match, left pattern will be checked first
