//
//  DeepLinkPattern.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public struct DeepLinkPatternParameter: RawRepresentable, Hashable {
    
    public private(set) var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public static func ==(lhs: DeepLinkPatternParameter, rhs: DeepLinkPatternParameter) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public var description: String {
        return rawValue
    }
    
}

public enum DeepLinkPattern: CustomStringConvertible, Equatable {
    
    case string(String)
    case param(DeepLinkPatternParameter)
    case or(DeepLinkPatternConvertible, DeepLinkPatternConvertible)
    case maybe(DeepLinkRoute)
    // can be used only in the end or between two string patterns
    case any
    
    public var description: String {
        switch self {
        case .string(let str): return str.description
        case .param(let param): return ":\(param.rawValue)"
        case .or(let lhs, let rhs): return "(\(lhs.description)|\(rhs.description))"
        case .maybe(let route): return "(\(route))"
        case .any: return "*"
        }
    }
    
    public static func ==(lhs: DeepLinkPattern, rhs: DeepLinkPattern) -> Bool {
        switch (lhs, rhs) {
        case let (.string(lhsString), .string(rhsString)):
            return lhsString == rhsString
        case let (.param(lhsParam), .param(rhsParam)):
            return lhsParam == rhsParam
        case let (.or(lhsOptions), .or(rhsOptions)):
            return lhsOptions.0.pattern == rhsOptions.0.pattern &&
                lhsOptions.1.pattern == rhsOptions.1.pattern
        case let (.maybe(lhsRoute), .maybe(rhsRoute)):
            return lhsRoute == rhsRoute
        case (.any, .any):
            return true
        default:
            return false
        }
    }
    
}
