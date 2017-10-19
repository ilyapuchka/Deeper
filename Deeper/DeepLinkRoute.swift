//
//  DeepLinkRoute.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public struct DeepLinkRoute: DeepLinkPatternConvertible, RawRepresentable, Hashable, ExpressibleByStringLiteral {
    
    public let pattern: [DeepLinkPathPattern]
    public let query: [DeepLinkQueryPattern]
    
    public let rawValue: String
    
    public init(pattern: [DeepLinkPathPattern], query: [DeepLinkQueryPattern] = []) {
        self.pattern = pattern.filter({
            if case let .string(value) = $0 { return !value.isEmpty }
            else { return true }
        })
        self.query = query
        let pathPattern = pattern.map({ "\($0)" }).joined(separator: "/")
        let queryPattern = query.map({ "\($0)" }).joined(separator: "&")
        self.rawValue = "\(pathPattern)\(!queryPattern.isEmpty ? "?\(queryPattern)" : "")"
    }
    
    public init(rawValue: String) {
        self.init(rawValue)
    }

    public init(_ rawValue: String) {
        self.init(pattern: rawValue.pattern, query: rawValue.query)
    }

    public init(stringLiteral value: String) {
        self.init(pattern: value.pattern)
    }

    public var hashValue: Int {
        return rawValue.hashValue
    }

    public static func ==(lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> Bool {
        return lhs.description == rhs.description
    }
    
    public var description: String {
        return rawValue
    }

}

public struct DeepLinkRouteWithQuery: CustomStringConvertible, ExpressibleByStringLiteral {
    public let route: DeepLinkRoute
    
    public init(stringLiteral value: String) {
        self.init(pattern: value.pattern, query: value.query)
    }

    init(pattern: [DeepLinkPathPattern], query: [DeepLinkQueryPattern]) {
        self.route = DeepLinkRoute(pattern: pattern, query: query)
    }
    
    public var description: String {
        return route.description
    }
    
}

public protocol DeepLinkRouteConvertible: CustomStringConvertible {
    var route: DeepLinkRoute { get }
}

extension DeepLinkRoute: DeepLinkRouteConvertible {
    public var route: DeepLinkRoute { return self }
}

extension DeepLinkRouteWithQuery: DeepLinkRouteConvertible {}

extension String: DeepLinkRouteConvertible {
    public var route: DeepLinkRoute { return DeepLinkRoute(self) }
}
