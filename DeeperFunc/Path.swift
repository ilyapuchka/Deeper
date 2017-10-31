//
//  Path.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 27/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

func lit(_ str: String) -> RoutePattern<Void, Path> {
    return .init(
        parse: { route in
            guard route.path.first == str else { return nil }
            return (RouteComponents(path: Array(route.path.dropFirst()), query: route.1), ())
    },
        print: { _ in
            return RouteComponents(path: [str], query: [:])
    }, template: str)
}

func pathParam<A>(_ iso: PartialIso<String, A>) -> RoutePattern<A, Path> {
    return .init(
        parse: { route in
            guard let pathComponent = route.path.first?.removingPercentEncoding, let parsed = iso.apply(pathComponent) else { return nil }
            return ((Array(route.path.dropFirst()), route.1), parsed)
    },
        print: { a in
            return RouteComponents(path: [iso.unapply(a)].flatMap({ $0 }), query: [:])
    }, template: pathParamTemplate(A.self))
}

// These are params transformations

public let string: RoutePattern<String, Path> = pathParam(.id)
public let int: RoutePattern<Int, Path> = pathParam(.int)
public let double: RoutePattern<Double, Path> = pathParam(.double)

// drop left param
infix operator /> : MultiplicationPrecedence
// carry on left param
infix operator >/> : MultiplicationPrecedence

extension RoutePattern where S == Path {

    static func or(_ lhs: RoutePattern, _ rhs: RoutePattern) -> RoutePattern {
        return .init(parse: parseAny(lhs, rhs), print: printAny(lhs, rhs), template: templateOr(lhs, rhs))
    }

    public static func >/>(lhs: RoutePattern, rhs: RoutePattern<Void, S>) -> RoutePattern {
        return .init(parse: parseLeft(lhs, rhs), print: printLeft(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func />(lhs: RoutePattern<Void, S>, rhs: RoutePattern) -> RoutePattern {
        return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func >/><B>(lhs: RoutePattern, rhs: RoutePattern<B, S>) -> RoutePattern<(A, B), S> {
        return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
    }

    public static func |(lhs: RoutePattern, rhs: RoutePattern) -> RoutePattern<Either<A, A>, S> {
        return .init(parse: parseEither(lhs, rhs), print: printEither(lhs, rhs), template: templateOr(lhs, rhs))
    }

    public static func |<B>(lhs: RoutePattern, rhs: RoutePattern<B, S>) -> RoutePattern<Either<A, B>, S> {
        return .init(parse: parseEither(lhs, rhs), print: printEither(lhs, rhs), template: templateOr(lhs, rhs))
    }
    
}

extension RoutePattern where A == Void, S == Path {
    
    public static func |(lhs: RoutePattern, rhs: RoutePattern) -> RoutePattern {
        return or(lhs, rhs)
    }

}
