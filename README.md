# Deeper

*Deeper* is a small framework that aims to help to put some structure in deeplink handling in your iOS app. Read [this article](http://ilya.puchka.me/deeplinks-no-brainer/) to get an overview of an idea behind it.

## Usage

### Define intents

First you start by describing *intents* of your deeplinks. It might be just opening some screen or performing an action on some object.

```swift
enum MyDeepLinkIntent {
  case showProfile(userId: String)
  case follow(userId: String)
  case retweet(tweetId: String)
}
```

You are not limited to using `enum` for that, but it will make it easier to keep track of number of intents and to have exhaustive handling.

### Register url patterns (aka routes)

Next you create a router object and define the "routes" for your deeplinks. You can use any router you want along with Deeper, you'll just need to write some extensions to bridge their APIs and implement `DeepLinkRouter` protocol. In the [article](http://ilya.puchka.me/deeplinks-no-brainer/) you can see an example of using [JLRoutes](https://github.com/joeldev/JLRoutes), which was an inspiration for Deeper's own router.

This project comes with to variants of routers, `Deeper.Router` and `DeeperFunc.Router`. You can use either of them which better suits your taste.

#### Deeper.Router

With `Deeper.Router` you register routes by registering handler closures which return spicific intent that should be performed when this deeplink is handeled or `nil` if it can't be properly handled. In this handler you have access to the full url, as well as to parsed parameters, extracted from the paths, based on the pattern that you are defining.

> Note: order of registration matters and defines priority of the route, first registered will be tried first when handling deeplink will happen.

```swift
import Deeper

let router = Router<Intent>(scheme: "myapp", rootDeepLinkHandler: appDelegate)

router.add(routes: ["profile" / ":userId" ]) { url, params in
  guard let userId = params[.init("userId")] else { return nil }
  return .showProfile(userId: userId)
}
```

#### DeeperFunc.Router

With `DeeperFunc.Router` your register routes by associating your intent cases (or any other constructor) with url patterns.

```swift
import DeeperFunc

let router = Router<Intent>(scheme: "myapp", rootDeepLinkHandler: appDelegate)

router.add(Intent.showProfile, route: "profile" /> string )
```

You will also need to make your intent type conform to `Route` protocol. For that you need to implement `Equatable` protocol and `deconstruct` function:

```swift
extension Intent: Route {

  func deconstruct<A>(_ constructor: (A) -> Intent) -> A? {
    switch self {
    case .showProfile(let values): return extract(constructor, values)
    case .follow(let values):      return extract(constructor, values)
    case .retweet(let values):     return extract(constructor, values)
    }
  } 

}
```

As you can see this is just a boilerplate. You can generate it with Sourcery as well as `Equatable` conformance.


### Implement handlers

Next you implement `DeepLinkHandler` protocol on some view controller or a separate object that you'll use for that if you want to extract this responsibility. You can also subclass `AnyDeepLinkHandler` class.

```swift
class ProfileScreen: UIViewController, DeepLinkHandler {

  var deeplinkHandling: DeepLinkHandling<MyDeepLinkIntent>?
	
  func open(deeplink: DeepLink<MyDeepLinkIntent>, animated: Bool) -> DeepLinkHandling<MyDeepLinkIntent> {
    // handle deeplink here and return one of the states based on the state of the app
    switch deeplink.intent {
    case .shopProfile(let userId):
      return .opened(deeplink) { [unowned self] animated in 
	//perform some side-effect that i.e. triggers loading of profile data
	self.userService.getProfile(forUserWithId: userId, completion: { result in self.updateView(result) })
      }
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
      return .passedThrough(deeplink) { [unowned self] animated in 
	// this method returns some other handler that will be invoked right after this closure returns
	return self.showProfileScreen(toOpen: deeplink, animanted: animated)
      }
    case .follow(let userId):
      return .opened(deeplink) { [unowned self] in
	self.userService.follow(userWithId: userId, completion: { result in self.showUserMessage(result) })
      }
    case .retweet(let tweetId):
      return .opened(deeplink) { [unowned self] in
	self.tweetService.retweet(tweetWithId: userId, completion: { result in self.showUserMessage(result) })
      }
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

To handle deeplinks you can follow two different scenarios:

- present destination screen from what ever screen user is currently on
- perform all navigation steps to get to the destination screen like if user would do all the navigation manually 

What approach to choose is up to you, but *Deeper* allows you to implement any of them. For that you are provided with a set of `DeepLinkHandling` options which represent different kind of possible states that you may be in while handling deeplink. You can provide optional side effects that will be executed right after `open(deeplink:animated:) -> DeepLinkHandling<Intent>` returns. This can help you to simplify unit tests.

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

In general that's it, the rest depends on your imagination and how your application is built. In the [article](http://ilya.puchka.me/deeplinks-no-brainer/) you can find more extensive code examples which are closer to real life project.

### TODO:

- example application
- improve documentation
- CocoaPods and SPM support
