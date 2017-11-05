//
//  Either.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 04/11/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public enum Either<A, B> {
    case left(A), right(B)
}

extension Either where A: Equatable, B: Equatable {
    public static func ==(_ lhs: Either, _ rhs: Either) -> Bool {
        switch (lhs, rhs) {
        case let (.left(lhs), .left(rhs)): return lhs == rhs
        case let (.right(lhs), .right(rhs)): return lhs == rhs
        default: return false
        }
    }
}

extension Either where A: Equatable, B == Void {
    public static func ==(_ lhs: Either, _ rhs: Either) -> Bool {
        switch (lhs, rhs) {
        case let (.left(lhs), .left(rhs)): return lhs == rhs
        case (.right, .right): return true
        default: return false
        }
    }
}

extension Either where B: Equatable, A == Void {
    public static func ==(_ lhs: Either, _ rhs: Either) -> Bool {
        switch (lhs, rhs) {
        case let (.right(lhs), .right(rhs)): return lhs == rhs
        case (.left, .left): return true
        default: return false
        }
    }
}
