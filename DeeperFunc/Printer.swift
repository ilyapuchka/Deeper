//
//  Printer.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 28/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public typealias Printer<A> = (A) -> RouteComponents?

func printLeft<L, LS, RS>(_ lhs: RoutePattern<L, LS>, _ rhs: RoutePattern<Void, RS>) -> Printer<L> {
    return { printBoth(lhs, rhs)(($0, ())) }
}

func printRight<R, LS, RS>(_ lhs: RoutePattern<Void, LS>, _ rhs: RoutePattern<R, RS>) -> Printer<R> {
    return { printBoth(lhs, rhs)(((), $0)) }
}

func printBoth<L, R, LS, RS>(_ lhs: RoutePattern<L, LS>, _ rhs: RoutePattern<R, RS>) -> Printer<(L, R)> {
    return {
        if let lhs = lhs.print($0.0), let rhs = rhs.print($0.1) {
            return RouteComponents(lhs.path + rhs.path, lhs.query.merging(rhs.query, uniquingKeysWith: { $1 }))
        } else {
            return lhs.print($0.0) ?? rhs.print($0.1)
        }
    }
}

func printEither<L, R, S>(_ lhs: RoutePattern<L, S>, _ rhs: RoutePattern<R, S>) -> Printer<Either<L, R>> {
    return {
        switch $0 {
        case let .left(a): return lhs.print(a)
        case let .right(b): return rhs.print(b)
        }
    }
}

func printAny<A, S>(_ lhs: RoutePattern<A, S>, _ rhs: RoutePattern<A, S>) -> Printer<A> {
    return {
        if let lhs = lhs.print($0), let rhs = rhs.print($0) {
            return (
                ["(\(lhs.path.joined(separator: "/"))|\(rhs.path.joined(separator: "/")))"],
                lhs.query.merging(rhs.query, uniquingKeysWith: { "(\($0)|\($1)))" })
            )
        }
        return lhs.print($0) ?? rhs.print($0)
    }
}

func templateAnd<A, B>(_ lhs: RoutePattern<A, Path>, _ rhs: RoutePattern<B, Path>) -> String {
    return "\(lhs.template)/\(rhs.template)"
}

func templateAnd<A, B, S: AnyPattern>(_ lhs: RoutePattern<A, Path>, _ rhs: RoutePattern<B, S>) -> String {
    return "\(lhs.template)/\(rhs.template)"
}

func templateAnd<A, B, S: ClosedPathPatternState>(_ lhs: RoutePattern<A, S>, _ rhs: RoutePattern<B, Query>) -> String {
    return "\(lhs.template)?\(rhs.template)"
}

func templateAnd<A, B>(_ lhs: RoutePattern<A, Query>, _ rhs: RoutePattern<B, Query>) -> String {
    return "\(lhs.template)&\(rhs.template)"
}

func templateOr<A, B, S>(_ lhs: RoutePattern<A, S>, _ rhs: RoutePattern<B, S>) -> String {
    return "(\(lhs.template)|\(rhs.template))"
}
