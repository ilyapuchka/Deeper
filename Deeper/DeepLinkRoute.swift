//
//  DeepLinkRoute.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public struct DeepLinkRoute: RawRepresentable, Hashable, ExpressibleByStringLiteral, ExpressibleByArrayLiteral {
    
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

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public init(_ rawValue: String) {
        self.init(pattern: rawValue.pattern, query: rawValue.query)
    }

    public init(arrayLiteral elements: DeepLinkPathPattern...) {
        self.init(pattern: elements)
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

public struct DeepLinkRouteWithQuery: CustomStringConvertible {
    public let route: DeepLinkRoute
    
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

extension String {
    
    var pattern: [DeepLinkPathPattern] {
        var component = self
        if let queryStart = component.index(of: "?") {
            component = String(component.prefix(upTo: queryStart))
        }
        var wrappedInBrackets = false
        if component.hasPrefix("(") && component.hasSuffix(")") {
            component = String(component.dropFirst().dropLast())
            wrappedInBrackets = true
        }
        
        if component == "*" {
            return [.any]
        } else if component.trimPrefix(":") {
            return [.param(DeepLinkPatternParameter(component))]
        } else {
            let orComponents = component.components(separatedBy: "|", excludingDelimiterBetween: ("(", ")"))
            if orComponents.count > 1 {
                let lhs = orComponents[0].pattern.route
                let rhs = orComponents.dropFirst().joined(separator: "|").pattern.route
                return [.or(lhs, rhs)]
            } else if wrappedInBrackets {
                return [.maybe(DeepLinkRoute(component))]
            } else {
                let components = component.components(separatedBy: "/", excludingDelimiterBetween: ("(", ")"))
                if components.count > 1 {
                    return components.flatMap({ $0.pattern })
                } else {
                    return [.string(component)]
                }
            }
        }
    }
    
}

extension String {
    
    var query: [DeepLinkQueryPattern] {
        guard let queryStart = index(of: "?") else { return [] }
        let component = String(suffix(from: queryStart).dropFirst())
        
        return component.components(separatedBy: "&").flatMap({ component in
            var component = component
            var wrappedInBrackets = false
            if component.hasPrefix("(") && component.hasSuffix(")") {
                component = String(component.dropFirst().dropLast())
                wrappedInBrackets = true
            }
            
            let orComponents = component.components(separatedBy: "|", excludingDelimiterBetween: ("(", ")"))
            if orComponents.count > 1, orComponents[0].hasPrefix(":"), orComponents[1].hasPrefix(":") {
                let lhs = DeepLinkPatternParameter(String(orComponents[0].dropFirst()))
                let rhs = DeepLinkPatternParameter(String(orComponents[1].dropFirst()))
                return .or(lhs, rhs)
            }
            
            guard component.hasPrefix(":") else { return nil }
            
            if wrappedInBrackets {
                return .maybe(DeepLinkPatternParameter(String(component.dropFirst())))
            } else {
                return .param(DeepLinkPatternParameter(String(component.dropFirst())))
            }
        })
    }
}
