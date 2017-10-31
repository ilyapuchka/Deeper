//
//  Any.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 26/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol AnyPattern {} // `any` pattern is used
public enum AnyStart: AnyPattern, OpenPatternState {} // any was used in the path and not closed
public enum AnyEnd: AnyPattern, ClosedPathPatternState {} // pattern ends with any, considered closed

public struct AwaitingPattern<LeftType, RightAfter, ResultParam> {
    let consume: (RoutePattern<RightAfter, Path>) -> RoutePattern<ResultParam, Path>
}

public func any<A>(_ next: RoutePattern<A, Path>) -> RoutePattern<A, AnyStart> {
    return .init(
        parse: { route in
            for index in route.path.dropFirst().indices {
                let rest = route.path.suffix(from: index)
                if let nextResult = next.parse(RouteComponents(Array(rest), route.query)) {
                    return nextResult
                }
            }
            return nil
    },
        print: {
            guard let nextResult = next.print($0) else { return nil }
            return RouteComponents(["*"] + nextResult.path, query: [:])
    }, template: "*/\(next.template)")
}

public let any: RoutePattern<Void, AnyEnd> = {
    return .init(
        parse: { route in
            return route.path.first != nil ? (rest: RouteComponents([], route.query), match: ()) : nil
    },
        print: { _ in
            return RouteComponents(path: ["*"], query: [:])
    }, template: "*")
}()

extension RoutePattern where S == Path {

    // string /> any
    public static func />(lhs: RoutePattern<Void, Path>, rhs: RoutePattern<A, AnyEnd>) -> RoutePattern<A, AnyEnd> {
        return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    // param >/> any
    public static func >/>(lhs: RoutePattern, rhs: RoutePattern<Void, AnyEnd>) -> RoutePattern<A, AnyEnd> {
        return .init(parse: parseLeft(lhs, rhs), print: printLeft(lhs, rhs), template: templateAnd(lhs, rhs))
    }

    // any /> something
    public static func />(lhs: @escaping (RoutePattern) -> RoutePattern<A, AnyStart>, rhs: RoutePattern) -> RoutePattern {
        let route = lhs(rhs)
        return .init(parse: route.parse, print: route.print, template: route.template)
    }

    // string /> any (/> param)
    public static func />(lhs: RoutePattern<Void, Path>, rhs: @escaping (RoutePattern<A, Path>) -> RoutePattern<A, AnyStart>) -> AwaitingPattern<Void, A, A> {
        return .init {
            let rhs = rhs($0)
            return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
        }
    }
    
    // (string />) any /> param
    public static func />(lhs: AwaitingPattern<Void, A, A>, rhs: RoutePattern<A, Path>) -> RoutePattern {
        return lhs.consume(rhs)
    }

    // param >/> any (>/> string)
    public static func >/>(lhs: RoutePattern, rhs: @escaping (RoutePattern<Void, Path>) -> RoutePattern<Void, AnyStart>) -> AwaitingPattern<A, Void, A> {
        return .init {
            let rhs = rhs($0)
            return .init(parse: parseLeft(lhs, rhs), print: printLeft(lhs, rhs), template: templateAnd(lhs, rhs))
        }
    }

    // param >/> any (>/> string)
    public static func >/>(lhs: RoutePattern, rhs: RoutePattern<Void, AnyStart>) -> RoutePattern {
        return .init(parse: parseLeft(lhs, rhs), print: printLeft(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    // (param >/>) any >/> string
    public static func >/>(lhs: AwaitingPattern<A, Void, A>, rhs: RoutePattern<Void, Path>) -> RoutePattern<A, Path> {
        return lhs.consume(rhs)
    }

    // param >/> any (>/> param)
    public static func >/><B>(lhs: RoutePattern<A, Path>, rhs: @escaping (RoutePattern<B, Path>) -> RoutePattern<B, AnyStart>) -> AwaitingPattern<A, B, (A, B)> {
        return .init {
            let rhs = rhs($0)
            return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
        }
    }
    
    // (param >/> any) >/> param
    public static func >/><B>(lhs: AwaitingPattern<A, B, (A, B)>, rhs: RoutePattern<B, Path>) -> RoutePattern<(A, B), Path> {
        return lhs.consume(rhs)
    }

}

extension RoutePattern where S == Query {
    
    public static func .?(lhs: RoutePattern<Void, AnyEnd>, rhs: RoutePattern) -> RoutePattern {
        return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func .?<B>(lhs: RoutePattern<B, AnyEnd>, rhs: RoutePattern) -> RoutePattern<(B, A), Query> {
        return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
    }

}
