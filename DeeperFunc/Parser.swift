//
//  Parser.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 28/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public typealias Parser<A> = (RouteComponents) -> (rest: RouteComponents, match: A)?

func parseLeft<L, LS, RS>(_ lhs: RoutePattern<L, LS>, _ rhs: RoutePattern<Void, RS>) -> Parser<L> {
    return { route in
        guard let result = parseBoth(lhs, rhs)(route) else { return nil }
        return (result.rest, result.match.0)
    }
}

func parseRight<R, LS, RS>(_ lhs: RoutePattern<Void, LS>, _ rhs: RoutePattern<R, RS>) -> Parser<R> {
    return { route in
        guard let result = parseBoth(lhs, rhs)(route) else { return nil }
        return (result.rest, result.match.1)
    }
}

func parseBoth<L, R, LS, RS>(_ lhs: RoutePattern<L, LS>, _ rhs: RoutePattern<R, RS>) -> Parser<(L, R)> {
    return { route in
        guard let lhsResult = lhs.parse(route) else { return nil }
        guard let rhsResult = rhs.parse(lhsResult.rest) else { return nil }
        return (rhsResult.rest, (lhsResult.match, rhsResult.match))
    }
}

func parseEither<L, R, S>(_ lhs: RoutePattern<L, S>, _ rhs: RoutePattern<R, S>) -> Parser<Either<L, R>> {
    return {
        lhs.parse($0).map({ ($0.rest, Either.left($0.match)) })
            ?? rhs.parse($0).map({ ($0.rest, Either.right($0.match)) })
    }
}

func parseAny<A, S>(_ lhs: RoutePattern<A, S>, _ rhs: RoutePattern<A, S>) -> Parser<A> {
    return { lhs.parse($0) ?? rhs.parse($0) }
}

