//
//  StringParser.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 31/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

private typealias StringParser<S: PatternState> = ([String]) -> (rest: [String], match: RoutePattern<Any, S>)?

private struct StringRouteParser<S: PatternState> {
    let parse: StringParser<S>
}

private func parseComponents<S>(_ components: [String], parsers: StringParser<S>...) -> (rest: [String], match: [RoutePattern<Any, S>])? {
    return parseComponents(components, parsers: parsers)
}

private func parseComponents<S>(_ components: [String], parsers: [StringParser<S>]) -> (rest: [String], match: [RoutePattern<Any, S>])? {
    var components = components
    var pathPatterns: [RoutePattern<Any, S>] = []
    
    componentsLoop: while !components.isEmpty {
        for parser in parsers {
            if let result = parser(components) {
                components = result.rest
                pathPatterns.append(result.match)
                continue componentsLoop
            }
        }
        return nil
    }
    
    return (components, pathPatterns)
}

private func parsePathParam<A>(pattern: RoutePattern<A, Path>, _ iso: PartialIso<String, A>) -> StringParser<Path> {
    return {
        guard let pathComponent = $0.first else { return nil }
        guard pathParamTemplate(A.self) == pathComponent else { return nil }

        let iso: PartialIso<A, Any> = iso <<< .string
        let typeErased: RoutePattern<Any, Path> = pattern.map(iso)
        return (Array($0.dropFirst()), typeErased)
    }
}

private let intPath: StringParser<Path> = parsePathParam(pattern: int, .int)
private let doublePath: StringParser<Path> = parsePathParam(pattern: double, .double)
private let stringPath: StringParser<Path> = parsePathParam(pattern: string, .id)

private let litPath: StringParser<Path> = { components in
    guard var pathComponent = components.first else { return nil }
    let typeErased: RoutePattern<Any, Path> = lit(pathComponent).map(.void)
    return (Array(components.dropFirst()), typeErased)
}

private let anyEndPath: StringParser<Path> = { components in
    guard components.count == 1, components[0] == "*" else { return nil }
    return ([], any.map(.void))
}

private let anyPath: StringParser<Path> = { components in
    guard components.count > 1, components[0] == "*", components[1] != "*" else { return nil }
    guard let result = parseComponents([components[1]], parsers: intPath, doublePath, stringPath, litPath) else { return nil }
    guard !result.match.isEmpty else { return nil }
    
    return (result.rest, any(result.match[0]).map(.id))
}

private func parsePathComponents(_ components: [String]) -> [RoutePattern<Any, Path>]? {
    return parseComponents(components, parsers: anyEndPath, anyPath, maybePath, intPath, doublePath, stringPath, litPath)?.match
}

private func parseQueryParam<A>(pattern: @escaping (String) -> RoutePattern<A, Query>, _ iso: PartialIso<String, A>) -> StringParser<Query> {
    return {
        guard var queryComponent = $0.first else { return nil }
        guard queryComponent.trimSuffix(queryParamTemplate(A.self, key: "")) else { return nil }
        
        let iso: PartialIso<A, Any> = iso <<< .string
        let typeErased: RoutePattern<Any, Query> = pattern(queryComponent).map(iso)
        return (Array($0.dropFirst()), typeErased)
    }
}

private let intQuery: StringParser<Query> = parseQueryParam(pattern: int, .int)
private let doubleQuery: StringParser<Query> = parseQueryParam(pattern: double, .double)
private let boolQuery: StringParser<Query> = parseQueryParam(pattern: bool, .bool)
private let stringQuery: StringParser<Query> = parseQueryParam(pattern: string, .id)

private let maybePath: StringParser<Path> = parseMaybe(intPath, doublePath, stringPath, litPath)
private let maybeQuery: StringParser<Query> = parseMaybe(intQuery, doubleQuery, boolQuery, stringQuery)

private func parseMaybe<S>(_ parsers: StringParser<S>...) -> StringParser<S> {
    return { components in
        guard var pathComponent = components.first else { return nil }
        guard pathComponent.trimPrefix("(") && pathComponent.trimSuffix(")") else { return nil }
        guard let result = parseComponents([pathComponent], parsers: parsers) else { return nil }
        guard !result.match.isEmpty else { return nil }
        
        return (result.rest, maybe(result.match[0]).map(.id))
    }
}

private func parseQueryComponents(_ components: [String]) -> [RoutePattern<Any, Query>]? {
    return parseComponents(components, parsers: maybeQuery, intQuery, doubleQuery, boolQuery, stringQuery)?.match
}

extension String {
    
    private var pathPatterns: [RoutePattern<Any, Path>]? {
        let path = index(of: "?").map(prefix(upTo:)).map(String.init) ?? self
        let pathComponents = path.components(separatedBy: "/", excludingDelimiterBetween: ("(", ")"))
        
        return parsePathComponents(pathComponents)
    }
    
    private var queryPatterns: [RoutePattern<Any, Query>]? {
        guard let queryStart = index(of: "?") else { return [] }
        
        let query = String(suffix(from: queryStart).dropFirst())
        guard !query.isEmpty else { return [] }
        
        let queryComponents = query.components(separatedBy: "&", excludingDelimiterBetween: ("(", ")"))
        return parseQueryComponents(queryComponents)
    }
    
    public var routePattern: RoutePattern<Any, Path>? {
        guard let pathPatterns = pathPatterns, let queryPatterns = queryPatterns else { return nil }

        let pathPattern = pathPatterns.suffix(from: 1).reduce(pathPatterns[0], and)
        if !queryPatterns.isEmpty {
            return queryPatterns.suffix(from: 1).reduce(and(pathPattern, queryPatterns[0]), and).map(.id)
        } else {
            return pathPattern
        }
    }
    
}

private func and(_ lhs: RoutePattern<Any, Path>, _ rhs: RoutePattern<Any, Path>) -> RoutePattern<Any, Path> {
    return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
}

private func and(_ lhs: RoutePattern<Any, Query>, _ rhs: RoutePattern<Any, Query>) -> RoutePattern<Any, Query> {
    return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
}

private func and(_ lhs: RoutePattern<Any, Path>, _ rhs: RoutePattern<Any, Query>) -> RoutePattern<Any, Query> {
    return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
}

private func parseBoth<S1, S2>(_ lhs: RoutePattern<Any, S1>, _ rhs: RoutePattern<Any, S2>) -> Parser<Any> {
    return { url in
        guard let lhsResult = lhs.parse(url) else { return nil }
        guard let rhsResult = rhs.parse(lhsResult.0) else { return nil }
        return (rhsResult.0, flatten(lhsResult.match, rhsResult.match ))
    }
}

private func printBoth<S1, S2>(_ lhs: RoutePattern<Any, S1>, _ rhs: RoutePattern<Any, S2>) -> Printer<Any> {
    return { value in
        if let (lhsValue, rhsValue) = value as? (Any, Any), let lhs = lhs.print(lhsValue), let rhs = rhs.print(rhsValue) {
            return RouteComponents(lhs.path + rhs.path, lhs.query.merging(rhs.query, uniquingKeysWith: { $1 }))
        } else if let lhs = lhs.print(value), let rhs = rhs.print(value)  {
            return RouteComponents(lhs.path + rhs.path, lhs.query.merging(rhs.query, uniquingKeysWith: { $1 }))
        } else {
            return nil
        }
    }
}
