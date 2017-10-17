//
//  Deeper.swift
//  Deeper
//
//  Created by Ilya Puchka on 28/09/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

var clearDeeplinkHandling = true
var logger: Logger? = Logger()

public func configure(clearDeeplinkHandling: Bool = true, logger: Logger? = Logger()) {
    Deeper.clearDeeplinkHandling = clearDeeplinkHandling
    Deeper.logger = logger
}

open class Logger {
    
    public init() {}

    open func log<Handler: DeepLinkHandler>(deeplink: DeepLink<Handler.Intent>, result: DeepLinkHandling<Handler.Intent>, handler: Handler) {
        print(result)
    }
    
}

public func /(lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + rhs.pattern)
}

public func /(lhs: DeepLinkPatternParameter, rhs: DeepLinkPatternParameter) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + rhs.pattern)
}

public func /(lhs: DeepLinkRoute, rhs: DeepLinkPatternParameter) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + rhs.pattern)
}

public func /(lhs: DeepLinkPatternParameter, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + rhs.pattern)
}

public func /(lhs: DeepLinkRoute, rhs: DeepLinkPattern) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + [rhs])
}

public func /(lhs: DeepLinkPattern, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [lhs] + rhs.pattern)
}

public func /(lhs: DeepLinkPattern, rhs: DeepLinkPatternParameter) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [lhs] + rhs.pattern)
}

public func /(lhs: DeepLinkPatternParameter , rhs: DeepLinkPattern) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + [rhs])
}

infix operator /? : MultiplicationPrecedence

public func /?(lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + [.maybe(rhs)])
}

public func /?(lhs: DeepLinkPatternParameter, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + [.maybe(rhs)])
}

public func /?(lhs: DeepLinkPattern, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [lhs] + [.maybe(rhs)])
}

public func |(lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.or(lhs, rhs)])
}

public func |(lhs: DeepLinkRoute, rhs: DeepLinkPatternParameter) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.or(lhs, rhs)])
}

public func |(lhs: DeepLinkPatternParameter, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.or(lhs, rhs)])
}

infix operator .? : MultiplicationPrecedence
infix operator .?? : MultiplicationPrecedence

public func .?(lhs: DeepLinkRoute, rhs: DeepLinkQueryPattern) -> DeepLinkRouteWithQuery {
    return DeepLinkRouteWithQuery(pattern: lhs.pattern, query: [rhs])
}

public func .?(lhs: DeepLinkRoute, rhs: DeepLinkPatternParameter) -> DeepLinkRouteWithQuery {
    return DeepLinkRouteWithQuery(pattern: lhs.pattern, query: [.param(rhs)])
}

public func .??(lhs: DeepLinkRoute, rhs: DeepLinkPatternParameter) -> DeepLinkRouteWithQuery {
    return DeepLinkRouteWithQuery(pattern: lhs.pattern, query: [.maybe(rhs)])
}

public func &(lhs: DeepLinkRouteWithQuery, rhs: DeepLinkQueryPattern) -> DeepLinkRouteWithQuery {
    return DeepLinkRouteWithQuery(pattern: lhs.route.pattern, query: lhs.route.query + [rhs])
}

public func &(lhs: DeepLinkRouteWithQuery, rhs: DeepLinkPatternParameter) -> DeepLinkRouteWithQuery {
    return DeepLinkRouteWithQuery(pattern: lhs.route.pattern, query: lhs.route.query + [.param(rhs)])
}

infix operator &? : MultiplicationPrecedence

public func &?(lhs: DeepLinkRouteWithQuery, rhs: DeepLinkPatternParameter) -> DeepLinkRouteWithQuery {
    return DeepLinkRouteWithQuery(pattern: lhs.route.pattern, query: lhs.route.query + [.maybe(rhs)])
}

public func |(lhs: DeepLinkPatternParameter, rhs: DeepLinkPatternParameter) -> DeepLinkQueryPattern {
    return .or(lhs, rhs)
}
