//
//  String.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 28/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

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
    
    public static func |(lhs: String, rhs: String) -> RoutePattern<Void, Path> {
        return RoutePattern<Void, Path>.or(lit(lhs), lit(rhs))
    }
    
    public static func |(lhs: String, rhs: RoutePattern<Void, Path>) -> RoutePattern<Void, Path> {
        return RoutePattern<Void, Path>.or(lit(lhs), rhs)
    }
    
    public static func |(lhs: RoutePattern<Void, Path>, rhs: String) -> RoutePattern<Void, Path> {
        return RoutePattern<Void, Path>.or(lhs, lit(rhs))
    }
    
    public static func |<A>(lhs: RoutePattern<A, Path>, rhs: String) -> RoutePattern<Either<A, Void>, Path> {
        let rhs = lit(rhs)
        return .init(parse: parseEither(lhs, rhs), print: printEither(lhs, rhs), template: templateOr(lhs, rhs))
    }

}

extension String {
    
    public static func .?<A>(lhs: String, rhs: RoutePattern<A, Query>) -> RoutePattern<A, Query> {
        return lit(lhs) .? rhs
    }
    
}

extension String {
    
    // string /> any (/> param)
    public static func /><R>(lhs: String, rhs: @escaping (RoutePattern<R, Path>) -> RoutePattern<R, AnyStart>) -> AwaitingPattern<Void, R, R> {
        return lit(lhs) /> rhs
    }
    
    // (param >/>) any >/> string
    public static func >/><L>(lhs: AwaitingPattern<L, Void, L>, rhs: String) -> RoutePattern<L, Path> {
        return lhs.consume(lit(rhs))
    }
    
    // (string /> any) /> string
    public static func />(lhs: AwaitingPattern<Void, Void, Void>, rhs: String) -> RoutePattern<Void, Path> {
        return lhs.consume(lit(rhs))
    }
    
    // string /> any
    public static func /><A>(lhs: String, rhs: RoutePattern<A, AnyEnd>) -> RoutePattern<A, AnyEnd> {
        return lit(lhs) /> rhs
    }

    // any /> string
    public static func />(lhs: @escaping (RoutePattern<Void, Path>) -> RoutePattern<Void, AnyStart>, rhs: String) -> RoutePattern<Void, Path> {
        return lhs /> lit(rhs)
    }
    
}
