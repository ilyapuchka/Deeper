//
//  Deeper.swift
//  Deeper
//
//  Created by Ilya Puchka on 28/09/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

var logger: Logger = Logger()

open class Logger {

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
