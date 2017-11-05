//
//  Utils.swift
//  DeeperFuncTests
//
//  Created by Ilya Puchka on 29/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation
import DeeperFunc

enum Intent: Route, Equatable {
    
    case empty
    case pathAndQueryParams(Int, String, Int, String)
    case singleParam(Int)
    case twoParams(Int, String)
    case anyMiddle
    case anyEnd
    case anyStart
    case anyMiddleParam(Int)
    case anyMiddleParams(Int, Int)
    case anyEndParam(Int)
    case anyStartParam(Int)
    case orPattern
    case eitherIntOrInt(Either<Int, Int>)
    case eitherIntOrString(Either<Int, String>)
    case eitherIntOrVoid(Either<Int, Void>)
    case optionalParam(Int?)
    case optionalSecondParam(Int, String?)

    func deconstruct<A>(_ constructor: ((A) -> Intent)) -> A? {
        switch self {
        case let .pathAndQueryParams(values as A) where self == constructor(values): return values
        case let .singleParam(values as A) where self == constructor(values): return values
        case let .twoParams(values as A) where self == constructor(values): return values
        case let .anyMiddleParam(values as A) where self == constructor(values): return values
        case let .anyMiddleParams(values as A) where self == constructor(values): return values
        case let .anyEndParam(values as A) where self == constructor(values): return values
        case let .anyStartParam(values as A) where self == constructor(values): return values
        case let .eitherIntOrInt(values as A) where self == constructor(values): return values
        case let .eitherIntOrString(values as A) where self == constructor(values): return values
        case let .eitherIntOrVoid(values as A) where self == constructor(values): return values
        case let .optionalParam(values as A) where self == constructor(values): return values
        case let .optionalSecondParam(values as A) where self == constructor(values): return values
        default: return nil
        }
    }
    
    static func ==(lhs: Intent, rhs: Intent) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty): return true
        case (.anyMiddle, .anyMiddle): return true
        case (.anyEnd, .anyEnd): return true
        case (.anyStart, .anyStart): return true
        case (.orPattern, .orPattern): return true
        case let (.pathAndQueryParams(lhs), .pathAndQueryParams(rhs)): return lhs == rhs
        case let (.singleParam(lhs), .singleParam(rhs)): return lhs == rhs
        case let (.twoParams(lhs), .twoParams(rhs)): return lhs == rhs
        case let (.anyMiddleParam(lhs), .anyMiddleParam(rhs)): return lhs == rhs
        case let (.anyMiddleParams(lhs), .anyMiddleParams(rhs)): return lhs == rhs
        case let (.anyEndParam(lhs), .anyEndParam(rhs)): return lhs == rhs
        case let (.anyStartParam(lhs), .anyStartParam(rhs)): return lhs == rhs
        case let (.eitherIntOrInt(lhs), .eitherIntOrInt(rhs)): return lhs == rhs
        case let (.eitherIntOrString(lhs), .eitherIntOrString(rhs)): return lhs == rhs
        case let (.eitherIntOrVoid(lhs), .eitherIntOrVoid(rhs)): return lhs == rhs
        case let (.optionalParam(lhs), .optionalParam(rhs)): return lhs == rhs
        case let (.optionalSecondParam(lhs1, lhs2), .optionalSecondParam(rhs1, rhs2)):
            return lhs1 == rhs1 && lhs2 == rhs2
        default: return false
        }
    }
}
