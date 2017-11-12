//
//  Deeper.swift
//  Deeper
//
//  Created by Ilya Puchka on 28/09/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public func /(lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + rhs.pattern)
}

public func /(lhs: DeepLinkPatternParameter, rhs: DeepLinkPatternParameter) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.param(lhs)] + [.param(rhs)])
}

public func /(lhs: DeepLinkRoute, rhs: DeepLinkPatternParameter) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + [.param(rhs)])
}

public func /(lhs: DeepLinkPatternParameter, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.param(lhs)] + rhs.pattern)
}

public func /(lhs: DeepLinkRoute, rhs: DeepLinkPathPattern) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + [rhs])
}

public func /(lhs: DeepLinkPathPattern, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [lhs] + rhs.pattern)
}

public func /(lhs: DeepLinkPathPattern, rhs: DeepLinkPatternParameter) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [lhs] + [.param(rhs)])
}

public func /(lhs: DeepLinkPatternParameter , rhs: DeepLinkPathPattern) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.param(lhs)] + [rhs])
}

infix operator /? : MultiplicationPrecedence

public func /?(lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: lhs.pattern + [.maybe(rhs)])
}

public func /?(lhs: DeepLinkPatternParameter, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.param(lhs)] + [.maybe(rhs)])
}

public func /?(lhs: DeepLinkPathPattern, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [lhs] + [.maybe(rhs)])
}

public func |(lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.or(lhs, rhs)])
}

public func |(lhs: DeepLinkRoute, rhs: DeepLinkPatternParameter) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.or(lhs, [.param(rhs)])])
}

public func |(lhs: DeepLinkPatternParameter, rhs: DeepLinkRoute) -> DeepLinkRoute {
    return DeepLinkRoute(pattern: [.or([.param(lhs)], rhs)])
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
