//
//  DeepLinkPattern.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public struct DeepLinkPatternParameter: RawRepresentable, Hashable, CustomStringConvertible {
    public enum ParamType: String {
        case int, double, string, bool
        func validate(_ value: String) -> Bool {
            switch self {
            case .int: return Int(value) != nil
            case .double: return Double(value) != nil
            case .bool: return Bool(value.lowercased()) != nil || value == "0" || value == "1"
            case .string: return true
            }
        }
    }
    
    public let rawValue: String
    public let type: ParamType?
    
    public init(rawValue: String) {
        self.init(rawValue)
    }
    
    public init(_ rawValue: String) {
        var _rawValue = rawValue.trimmingSuffix(")")
        if _rawValue.trimPrefix("int(") {
            self.init(_rawValue, type: .int)
        } else if _rawValue.trimPrefix("double(") {
            self.init(_rawValue, type: .double)
        } else if _rawValue.trimPrefix("string(") {
            self.init(_rawValue, type: .string)
        } else if _rawValue.trimPrefix("bool(") {
            self.init(_rawValue, type: .bool)
        } else {
            self.init(rawValue, type: nil)
        }
    }

    public init(_ rawValue: String, type: ParamType?) {
        self.rawValue = rawValue
        self.type = type
    }

    public static func int(_ rawValue: String) -> DeepLinkPatternParameter {
        return .init(rawValue, type: .int)
    }

    public static func double(_ rawValue: String) -> DeepLinkPatternParameter {
        return .init(rawValue, type: .double)
    }

    public static func string(_ rawValue: String) -> DeepLinkPatternParameter {
        return .init(rawValue, type: .string)
    }

    public static func bool(_ rawValue: String) -> DeepLinkPatternParameter {
        return .init(rawValue, type: .bool)
    }

    public static func ==(lhs: DeepLinkPatternParameter, rhs: DeepLinkPatternParameter) -> Bool {
        return lhs.rawValue == rhs.rawValue && lhs.type == rhs.type
    }
    
    public var hashValue: Int {
        return rawValue.hashValue ^ (type?.hashValue ?? 0)
    }
    
    public var description: String {
        if let type = type {
            return "\(type)(\(rawValue))"
        } else {
            return rawValue
        }
    }
    
}

public enum DeepLinkPathPattern: CustomStringConvertible, Equatable {
    
    case string(String)
    case param(DeepLinkPatternParameter)
    case or(DeepLinkRoute, DeepLinkRoute)
    case maybe(DeepLinkRoute)
    // can be used only in the end or between two string patterns
    case any
    
    public var description: String {
        switch self {
        case .string(let str): return str
        case .param(let param): return ":\(param)"
        case .or(let lhs, let rhs): return "(\(lhs)|\(rhs))"
        case .maybe(let route): return "(\(route))"
        case .any: return "*"
        }
    }
    
    public static func ==(lhs: DeepLinkPathPattern, rhs: DeepLinkPathPattern) -> Bool {
        switch (lhs, rhs) {
        case let (.string(lhsString), .string(rhsString)):
            return lhsString == rhsString
        case let (.param(lhsParam), .param(rhsParam)):
            return lhsParam == rhsParam
        case let (.or(lhsOptions), .or(rhsOptions)):
            return lhsOptions.0 == rhsOptions.0 && lhsOptions.1 == rhsOptions.1
        case let (.maybe(lhsRoute), .maybe(rhsRoute)):
            return lhsRoute == rhsRoute
        case (.any, .any):
            return true
        default:
            return false
        }
    }
    
}
