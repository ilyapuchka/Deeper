//
//  Parser.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 28/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public typealias Parser<A> = (RouteComponents) -> (rest: RouteComponents, match: A)?

func parseLeft<L, R, LS, RS>(_ lhs: RoutePattern<L, LS>, _ rhs: RoutePattern<R, RS>) -> Parser<L> {
    return { route in
        guard let result = parseBoth(lhs, rhs)(route) else { return nil }
        return (result.rest, result.match.0)
    }
}

func parseRight<L, R, LS, RS>(_ lhs: RoutePattern<L, LS>, _ rhs: RoutePattern<R, RS>) -> Parser<R> {
    return { route in
        guard let result = parseBoth(lhs, rhs)(route) else { return nil }
        return (result.rest, result.match.1)
    }
}

func parseBoth<L, R, LS, RS>(_ lhs: RoutePattern<L, LS>, _ rhs: RoutePattern<R, RS>) -> Parser<(L, R)> {
    return { route in
        guard let lhsResult = lhs.parse(route) else { return nil }
        guard let rhsResult = rhs.parse(lhsResult.0) else { return nil }
        return (rhsResult.0, (lhsResult.1, rhsResult.1))
    }
}

func parseEither<L, R, LS, RS>(_ lhs: RoutePattern<L, LS>, _ rhs: RoutePattern<R, RS>) -> Parser<Either<L, R>> {
    return { lhs.parse($0).map({ ($0.0, Either.left($0.1)) }) ?? rhs.parse($0).map({ ($0.0, Either.right($0.1)) }) }
}

func parseAny<A, LS, RS>(_ lhs: RoutePattern<A, LS>, _ rhs: RoutePattern<A, RS>) -> Parser<A> {
    return { lhs.parse($0) ?? rhs.parse($0) }
}
