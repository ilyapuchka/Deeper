//
//  DeepLinkRoute.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public struct DeepLinkRoute: DeepLinkPatternConvertible, RawRepresentable {
    
    public let pattern: [DeepLinkPattern]
    public let rawValue: String
    
    public init(pattern: [DeepLinkPattern]) {
        self.pattern = pattern.filter({
            if case let .string(value) = $0 { return !value.isEmpty }
            else { return true }
        })
        self.rawValue = pattern.map({ $0.description }).joined(separator: "/")
    }
    
    public init(rawValue: String) {
        self.init(rawValue)
    }

    public init(_ rawValue: String) {
        self.init(pattern: rawValue.pattern)
    }

    public func match(url: URL) -> DeepLinkPatternMatcher.Result {
        let matcher = DeepLinkPatternMatcher(
            pattern: pattern,
            pathComponents: ([url.host].flatMap({ $0 }) + url.pathComponents)
        )
        return matcher.match()
    }
    
}

extension DeepLinkRoute: Hashable {
    
    public var hashValue: Int {
        return rawValue.hashValue
    }

    public static func ==(lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> Bool {
        return lhs.description == rhs.description
    }
    
}

extension DeepLinkRoute: CustomStringConvertible {

    public var description: String {
        return rawValue
    }

}

extension DeepLinkRoute: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(pattern: value.pattern)
    }

}
