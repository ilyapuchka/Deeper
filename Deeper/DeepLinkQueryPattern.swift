//
//  DeepLinkQueryPattern.swift
//  Deeper
//
//  Created by Ilya Puchka on 16/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public enum DeepLinkQueryPattern: CustomStringConvertible, Equatable {
    case param(DeepLinkPatternParameter)
    case maybe(DeepLinkPatternParameter)
    case or(DeepLinkPatternParameter, DeepLinkPatternParameter)
    
    public var description: String {
        switch self {
        case let .param(param): return ":\(param)"
        case let .maybe(param): return "(:\(param))"
        case let .or(lhs, rhs): return "(:\(lhs)|:\(rhs))"
        }
    }
    
    public static func ==(lhs: DeepLinkQueryPattern, rhs: DeepLinkQueryPattern) -> Bool {
        switch (lhs, rhs) {
        case let (.param(lhsParam), .param(rhsParam)):
            return lhsParam == rhsParam
        case let (.maybe(lhsParam), .maybe(rhsParam)):
            return lhsParam == rhsParam
        case let (.or(lhsParams), .or(rhsParams)):
            return lhsParams == rhsParams
        default:
            return false
        }
    }
    
}
