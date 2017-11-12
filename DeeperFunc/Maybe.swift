//
//  Maybe.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 29/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

func maybe(_ route: RoutePattern<Void, Path>) -> RoutePattern<Void, Path> {
    return .init(parse: { route.parse($0) ?? ($0, ()) }, print: route.print, template: "(\(route.template))")
}

func maybe<A, S>(_ route: RoutePattern<A, S>) -> RoutePattern<A?, S> {
    return .init(parse: { url in
        guard let result = route.parse(url) else { return (url, nil) }
        return (result.rest, result.match)
    }, print: {
        return $0.flatMap(route.print)
    }, template: "(\(route.template))")
}

infix operator /? : MultiplicationPrecedence

extension RoutePattern where S == Path {
    
    public static func /?(lhs: RoutePattern, rhs: RoutePattern<Void, S>) -> RoutePattern {
        let rhs = maybe(rhs)
        return .init(parse: parseLeft(lhs, rhs), print: printLeft(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func /?(lhs: RoutePattern<Void, S>, rhs: RoutePattern) -> RoutePattern<A?, S> {
        let rhs = maybe(rhs)
        return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func /?<B>(lhs: RoutePattern, rhs: RoutePattern<B, S>) -> RoutePattern<(A, B?), S> {
        let rhs = maybe(rhs)
        return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
    }

}

extension String {

    public static func /?(lhs: String, rhs: String) -> RoutePattern<Void, Path> {
        return lit(lhs) /? lit(rhs)
    }

    public static func /?<A>(lhs: RoutePattern<A, Path>, rhs: String) -> RoutePattern<A, Path> {
        return lhs /? lit(rhs)
    }

    public static func /?<A>(lhs: String, rhs: RoutePattern<A, Path>) -> RoutePattern<A?, Path> {
        return lit(lhs) /? rhs
    }
    
}

infix operator .?? : MultiplicationPrecedence
infix operator &? : MultiplicationPrecedence

extension RoutePattern where S == Query {
    
    public static func .??(lhs: RoutePattern<Void, Path>, rhs: RoutePattern) -> RoutePattern<A?, Query> {
        let rhs = maybe(rhs)
        return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func .??<B>(lhs: RoutePattern<B, Path>, rhs: RoutePattern) -> RoutePattern<(B, A?), Query> {
        let rhs = maybe(rhs)
        return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
    }

    public static func &?<B>(lhs: RoutePattern, rhs: RoutePattern<B, Query>) -> RoutePattern<(A, B?), Query> {
        let rhs = maybe(rhs)
        return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
    }

}

extension String {
    
    public static func .??<A>(lhs: String, rhs: RoutePattern<A, Query>) -> RoutePattern<A?, Query> {
        return lit(lhs) .?? rhs
    }

}
