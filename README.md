# Deeper

*Deeper* is a little framework that aims to help to put some structure in deeplink handling in your iOS app. Read [this article](http://ilya.puchka.me/deeplinks-no-brainer/) to get an overview of an idea behind it.

## Usage

### Define intents

First you start desribing *intents* of your deeplinks. It might be just opening some screen or performing an action on some object.

```swift
enum MyDeepLinkIntent {
  case showProfile(userId: String)
  case follow(userId: String)
  case retweet(tweetId: String)
}
```

You are not limited to using `enum` for that, but it will make it easier to keep track of number of intents and to have exhaustive handling.

### Register url patterns (aka routes)

Next you create a router object and define the "routes" for your deeplinks by registering handler closures which return spicific intent that should be performed when this deeplink is handeled or nil if it can't be properly handeled. In this handler you have access to the full url, as well as to parsed parameters, extracted from the paths, based on the pattern that you are defining.

> Note: order of registration matters and defines priority of the route, first registered will be tried first when handling deeplink will happen.

```swift
let router = DeepLinkRouter(scheme: "myapp", rootDeepLinkHandler: appDelegate)

router.add(routes: ["profile/:userId"]) { url, params in 
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

You can also use optional, conditional (this-or-this), wildcard or typed path components. Avoid very complex patterns because Swift can simply fail to compile too complex expressions, but if you need you can use string format:

```swift
// match any number of paths before "profile"
route.add(routes: [ .any / .profile / .userId ]) { ... }
route.add(routes: [ "*/profile/:userId" ]) { ... }

// match "profile" or "user" path
route.add(routes: [ .profile | "user" / .userId ]) { }
route.add(routes: [ "(profile|user)/:userId" ]) { }

// match "profile/info/123" or just "profile/123"
route.add(routes: [ .profile /? "info" / .userId ]) { }
route.add(routes: [ "profile/(info)/:userId" ]) { }

// match "profile/123" but not "profile/abc"
route.add(routes: [ .profile / .num("userId") ])
route.add(routes: [ "profile/:num(userId)" ])
```

#### Query parameters

Along with path path components you can match query parameters. Query parameters will be matched even if they appear in url in a different order then in a pttern. Url also can have any other parameters, they will be simply ignored during matching. Query paremeters in a pattern are required unless they are explicitely marked as optional using `.maybe` or `.or` pattern.

```swift
// match `profile/userId=123&locale=us`
route.add(routes: [ .any / .profile .? .userId & .locale ]) { ... }
route.add(routes: [ "*/profile?:userId&:locale" ]) { ... }

// match `profile/userId=123&locale=us` and `profile/userId=123`
route.add(routes: [ .any / .profile .? .userId &? .locale ]) { ... }
route.add(routes: [ "*/profile?:userId&:locale" ]) { ... }
```

#### Custom operators

`/` - concatenates parts of path into a single route
`/?` - same as `/` but makes following path pattern optional (the same as using `.maybe` pattern)
`.?` - marks end of path pattern and start of query pattern, appends first query pattern to the route
`.&` - appends following query pattern to the route, can only be used after applying `.?` or `.??`
`.??` / `.&?` - the same as `.?` / `.&` but makes following query pattern optional (the same as using `.maybe` pattern)
`|` - defines a pattern with two alternatives, either left or right pattern should match, left pattern will be checked first (the same as using `.or` pattern)


### Implement handlers

Next you implement `DeepLinkHandler` protocol on some view controller or a separate object that you'll use for that if you want to extract this responsibility. You can also subclass `AnyDeepLinkHandler` class.

```swift
class ProfileScreen: UIViewController, DeepLinkHandler {

	var deeplinkHandling: DeepLinkHandling<MyDeepLinkIntent>?
	
	func open(deeplink: DeepLink<MyDeepLinkIntent>, animated: Bool) -> DeepLinkHandling<MyDeepLinkIntent> {
		// handle deeplink here and return one of the states based on the state of the app
		switch deeplink.intent {
		case .shopProfile(let userId):
			return .opened(deeplink, { [unowned self] animated in 
				//perform some side-effect that i.e. triggers loading of profile data
				self.userService.getProfile(forUserWithId: userId, completion: { result in self.updateView(result) })
			})
		default:
			// fail on any other deeplinks as they are not supported by this screen
			// you can also use assertions here if you like to catch this earlier
			return .rejected(deeplink, nil)
		}
	}

}
```

It's adviced to also implement this protocol on app delegate or any other "root" object that will be always an entry point for deeplink handling. This will ensure predictable control flow both in "cold" and "warm" start.

```swift
extension AppDelegate: AnyDeepLinkHandler<MyDeepLinkIntent> {

	func open(deeplink: DeepLink<MyDeepLinkIntent>, animated: Bool) -> DeepLinkHandling<MyDeepLinkIntent> {
		// start handling deeplink here by deciding i.e. to present destination screen modally
		// or passing the control flow to some other handler, i.e. root tab bar controller
		// that will decided to what tab to switch and so on
		switch deeplink.intent {
		case .showProfile:
			return .passedThrough(deeplink, { [unowned self] animated in 
				// this method returns some other handler that will be invoked right after this closure returns
				return self.showProfileScreen(toOpen: deeplink, animanted: animated)
			})
		case .follow(let userId):
			return .opened(deeplink, { [unowned self] in
				self.userService.follow(userWithId: userId, completion: { result in self.showUserMessage(result) })
			})
		case .retweet(let tweetId):
			return .opened(deeplink, { [unowned self] in
				self.tweetService.retweet(tweetWithId: userId, completion: { result in self.showUserMessage(result) })
			})
		}
	}

}

let router = DeepLinkRouter(scheme: "myapp", rootDeepLinkHandler: appDelegate)
```

### Trigger deeplink handling

That boils down to just calling `router.open(url: url)` in the app delegate:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
	return router.open(url: url)
}
```

When `open(url:)` is called router will search for the pattern that matches this url and will invoke corresponding handler to get the intent from it. If some handler returns `nil` it will continue to match other handlers until it tries all of them. When matching pattern is found router will create `DeepLink` from url and intent returned by handler closure and will pass it to `open(deeplink:animated:) -> DeepLinkHandling<Intent>` method of a `rootDeepLinkHandler`.

> Note: you can use any other deeplink router you want along with Deeper, you'll just need to write some extensions to bridge their APIs. In the [articale](http://ilya.puchka.me/deeplinks-no-brainer/) you can see an example of using [JLRoutes](https://github.com/joeldev/JLRoutes), which was an inspiration for Deeper router.

To handle deeplinks you can adopt two different scenarios:

- open destination screen from what ever screen user is currently on
- perform all navigation to get to the destination screen like if user would do all the navigation manually 

What approach to choose is up to you, but *Deeper* allows you to implement any of them. For that you are provided with a set of `DeepLinkHandling` options which represent different kind of possible states that you may be in while handling deeplink. You can provide optional side effects that will be executed right after `open(deeplink:animated:) -> DeepLinkHandling<MyDeepLinkIntent>` returns. This can help you to simplify unit tests.

```swift
public enum DeepLinkHandling<Intent> {
    
    /// Return this state if deeplink successfully handled
    case opened(DeepLink<Intent>, ((Bool) -> Void)?)
    
    /// Return this state if deeplink was rejected because it can't be handeled, with optional error
    case rejected(DeepLink<Intent>, Error?)
    
    /// Return this state if deeplink handling delayed because more data is needed
    case delayed(DeepLink<Intent>, Bool, ((Bool) -> Void)?)
    
    /// Return this state if deeplink was passed through to some other handler
    case passedThrough(DeepLink<Intent>, ((Bool) -> AnyDeepLinkHandler<Intent>)?)
    
}

```

In general that's it, the rest depends on your imagination and how your application is built. In the [articale](http://ilya.puchka.me/deeplinks-no-brainer/) you can find more extensive code examples more close to real life project.

### TODO:

- example application
- improve documentation
- CocoaPods and SPM support
