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

extension RoutePattern {
    
    public static func |<B>(lhs: RoutePattern, rhs: RoutePattern<B, S>) -> RoutePattern<Either<A, B>, S> {
        return .init(parse: parseEither(lhs, rhs), print: printEither(lhs, rhs), template: templateOr(lhs, rhs))
    }
    
}

extension RoutePattern where A == Void, S == Path {
    
    public static func |(lhs: RoutePattern, rhs: RoutePattern) -> RoutePattern {
        return .init(parse: parseAny(lhs, rhs), print: printAny(lhs, rhs), template: templateOr(lhs, rhs))
    }

}

extension String {
    
    public static func |(lhs: String, rhs: String) -> RoutePattern<Void, Path> {
        return lit(lhs) | lit(rhs)
    }
    
    public static func |(lhs: String, rhs: RoutePattern<Void, Path>) -> RoutePattern<Void, Path> {
        return lit(lhs) | rhs
    }

    public static func |<A>(lhs: String, rhs: RoutePattern<A, Path>) -> RoutePattern<Either<Void, A>, Path> {
        return lit(lhs) | rhs
    }

    public static func |(lhs: RoutePattern<Void, Path>, rhs: String) -> RoutePattern<Void, Path> {
        return lhs | lit(rhs)
    }

    public static func |<A>(lhs: RoutePattern<A, Path>, rhs: String) -> RoutePattern<Either<A, Void>, Path> {
        return lhs | lit(rhs)
    }

}
