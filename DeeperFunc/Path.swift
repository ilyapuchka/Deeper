//
//  Path.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 27/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

func lit(_ str: String) -> RoutePattern<Void, Path> {
    return .init(parse: { route in
        guard route.path.first == str else { return nil }
        return ((Array(route.path.dropFirst()), route.query), ())
    }, print: { _ in
        return ([str], [:])
    }, template: str)
}

func pathParam<A>(_ apply: @escaping (String) -> A?, _ unapply: @escaping (A) -> String?) -> RoutePattern<A, Path> {
    return .init(parse: { route in
        guard let pathComponent = route.path.first, let parsed = apply(pathComponent) else { return nil }
        return ((Array(route.path.dropFirst()), route.query), parsed)
    }, print: { a in
        guard let string = unapply(a) else { return nil }
        return ([string], [:])
    }, template: pathParamTemplate(A.self))
}

// These are params transformations

public let string = pathParam(String.init, String.init)
public let int = pathParam(Int.init, String.init)
public let double = pathParam(Double.init, String.init)

// drop left param
infix operator /> : MultiplicationPrecedence
// carry on left param
infix operator >/> : MultiplicationPrecedence

extension RoutePattern where S == Path {

    public static func >/>(lhs: RoutePattern, rhs: RoutePattern<Void, S>) -> RoutePattern {
        return .init(parse: parseLeft(lhs, rhs), print: printLeft(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func />(lhs: RoutePattern<Void, S>, rhs: RoutePattern) -> RoutePattern {
        return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func >/><B>(lhs: RoutePattern, rhs: RoutePattern<B, S>) -> RoutePattern<(A, B), S> {
        return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
    }

}

func and(_ lhs: RoutePattern<Void, Path>, _ rhs: RoutePattern<Void, Path>) -> RoutePattern<Void, Path> {
    return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
}

extension String {
    
    public static func />(lhs: String, rhs: String) -> RoutePattern<Void, Path> {
        return and(lit(lhs), lit(rhs))
    }
    
    public static func />(lhs: String, rhs: RoutePattern<Void, Path>) -> RoutePattern<Void, Path> {
        return and(lit(lhs), rhs)
    }
    
    public static func />(lhs: RoutePattern<Void, Path>, rhs: String) -> RoutePattern<Void, Path> {
        return and(lhs, lit(rhs))
    }
    
    public static func /><A>(lhs: String, rhs: RoutePattern<A, Path>) -> RoutePattern<A, Path> {
        return lit(lhs) /> rhs
    }
    
    public static func >/><A>(lhs: RoutePattern<A, Path>, rhs: String) -> RoutePattern<A, Path> {
        return lhs >/> lit(rhs)
    }
    
}
