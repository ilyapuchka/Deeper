//
//  Query.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 26/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

// TODO: why not to clear out query params after they are matched?
func queryParam<A>(_ key: String, _ apply: @escaping (String) -> A?, _ unapply: @escaping (A) -> String?) -> RoutePattern<A, Query> {
    return .init(parse: { route in
        guard let queryValue = route.query[key], let parsed = apply(queryValue) else { return nil }
        return (route, parsed)
    }, print: { a in
        guard let value = unapply(a) else { return nil }
        return ([], [key: value])
    }, template: queryParamTemplate(A.self, key: key))
}

public func string(_ key: String) -> RoutePattern<String, Query> { return queryParam(key, String.init, String.init) }
public func int(_ key: String) -> RoutePattern<Int, Query> { return queryParam(key, Int.init, String.init) }
public func double(_ key: String) -> RoutePattern<Double, Query> { return queryParam(key, Double.init, String.init) }
public func bool(_ key: String) -> RoutePattern<Bool, Query> { return queryParam(key, Bool.fromString, Bool.toString) }

extension Bool {
    static func fromString(_ stringValue: String) -> Bool? {
        switch stringValue {
        case "0": return false
        case "1": return true
        default: return Bool(stringValue.lowercased())
        }
    }
    
    static func toString(_ boolValue: Bool) -> String {
        return boolValue ? "true" : "false"
    }
}

infix operator .? : MultiplicationPrecedence

extension RoutePattern where S == Query {

    public static func .?(lhs: RoutePattern<Void, Path>, rhs: RoutePattern) -> RoutePattern {
        return .init(parse: parseRight(lhs, rhs), print: printRight(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
    public static func .?<B>(lhs: RoutePattern<B, Path>, rhs: RoutePattern) -> RoutePattern<(B, A), Query> {
        return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
    }

    public static func &<B>(lhs: RoutePattern, rhs: RoutePattern<B, Query>) -> RoutePattern<(A, B), Query> {
        return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
    }
    
}

extension String {
    
    public static func .?<A>(lhs: String, rhs: RoutePattern<A, Query>) -> RoutePattern<A, Query> {
        return lit(lhs) .? rhs
    }
    
}
