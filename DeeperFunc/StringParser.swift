//
//  StringParser.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 31/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

typealias StringParser<S: PatternState> = ([String]) -> (rest: [String], match: [RoutePattern<Any, S>])?

extension Array {
    func flatMapFirst<T>(where transform: (Element) throws -> T?) rethrows -> T? {
        for element in self {
            if let transformed = try transform(element) { return transformed }
        }
        return nil
    }
}

func parseComponents<S>(with parsers: [StringParser<S>]) -> StringParser<S> {
    return { components in
        var components = components
        var pathPatterns = [RoutePattern<Any, S>]()
        while !components.isEmpty {
            guard let result = parsers.flatMapFirst(where: { parse in parse(components) }) else { return nil }
            
            pathPatterns.append(contentsOf: result.match)
            components = result.rest
        }

        return (rest: components, match: pathPatterns)
    }
}

let parsePathComponents = parseComponents(with: [anyEndPath, anyPath, maybePath, intPath, doublePath, stringPath, litPath])
let parseQueryComponents = parseComponents(with: [maybeQuery, intQuery, doubleQuery, boolQuery, stringQuery])

func parsePathParam<A>(pattern: RoutePattern<A, Path>) -> StringParser<Path> {
    return {
        guard let pathComponent = $0.first else { return nil }
        guard pathParamTemplate(A.self) == pathComponent else { return nil }
        
        return (Array($0.dropFirst()), [pattern.map(.any)])
    }
}

let intPath: StringParser<Path> = parsePathParam(pattern: int)
let doublePath: StringParser<Path> = parsePathParam(pattern: double)
let stringPath: StringParser<Path> = parsePathParam(pattern: string)

let litPath: StringParser<Path> = { components in
    guard var pathComponent = components.first else { return nil }
    let typeErased: RoutePattern<Any, Path> = lit(pathComponent).map(.void)
    return (Array(components.dropFirst()), [typeErased])
}

let anyEndPath: StringParser<Path> = { components in
    guard components.count == 1, components[0] == "*" else { return nil }
    return ([], [any.map(.void)])
}

let anyPath: StringParser<Path> = { components in
    guard components.count > 1, components[0] == "*", components[1] != "*" else { return nil }
    let parseNext = parseComponents(with: [intPath, doublePath, stringPath, litPath])
    guard let result = parseNext([components[1]]) else { return nil }
    guard !result.match.isEmpty else { return nil }
    
    return (Array(components.suffix(from: 2)), [any(result.match[0]).map(.id)])
}

func parseQueryParam<A>(pattern: @escaping (String) -> RoutePattern<A, Query>) -> StringParser<Query> {
    return {
        guard var queryComponent = $0.first else { return nil }
        guard queryComponent.trimSuffix(queryParamTemplate(A.self, key: "")) else { return nil }
        
        return (Array($0.dropFirst()), [pattern(queryComponent).map(.any)])
    }
}

let intQuery: StringParser<Query> = parseQueryParam(pattern: int)
let doubleQuery: StringParser<Query> = parseQueryParam(pattern: double)
let boolQuery: StringParser<Query> = parseQueryParam(pattern: bool)
let stringQuery: StringParser<Query> = parseQueryParam(pattern: string)

let maybePath: StringParser<Path> = parseMaybe(parseComponents(with: [intPath, doublePath, stringPath, litPath]))
let maybeQuery: StringParser<Query> = parseMaybe(parseComponents(with: [intQuery, doubleQuery, boolQuery, stringQuery]))

func parseMaybe<S>(_ parse: @escaping StringParser<S>) -> StringParser<S> {
    return { components in
        guard var pathComponent = components.first else { return nil }
        guard pathComponent.trimPrefix("(") && pathComponent.trimSuffix(")") else { return nil }
        guard let result = parse([pathComponent]) else { return nil }
        guard !result.match.isEmpty else { return nil }
        
        return (result.rest, [maybe(result.match[0]).map(unwraped(.id))])
    }
}

extension String {
    
    var pathPatterns: [RoutePattern<Any, Path>]? {
        let path = index(of: "?").map(prefix(upTo:)).map(String.init) ?? self
        let pathComponents = path.components(separatedBy: "/", excludingDelimiterBetween: ("(", ")"))
        
        return parsePathComponents(pathComponents)?.match
    }
    
    var queryPatterns: [RoutePattern<Any, Query>]? {
        guard let queryStart = index(of: "?") else { return [] }
        
        let query = String(suffix(from: queryStart).dropFirst())
        guard !query.isEmpty else { return [] }
        
        let queryComponents = query.components(separatedBy: "&", excludingDelimiterBetween: ("(", ")"))
        return parseQueryComponents(queryComponents)?.match
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

func and(_ lhs: RoutePattern<Any, Path>, _ rhs: RoutePattern<Any, Path>) -> RoutePattern<Any, Path> {
    return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
}

func and(_ lhs: RoutePattern<Any, Query>, _ rhs: RoutePattern<Any, Query>) -> RoutePattern<Any, Query> {
    return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
}

func and(_ lhs: RoutePattern<Any, Path>, _ rhs: RoutePattern<Any, Query>) -> RoutePattern<Any, Query> {
    return .init(parse: parseBoth(lhs, rhs), print: printBoth(lhs, rhs), template: templateAnd(lhs, rhs))
}

func parseBoth<S1, S2>(_ lhs: RoutePattern<Any, S1>, _ rhs: RoutePattern<Any, S2>) -> Parser<Any> {
    return { url in
        guard let lhsResult = lhs.parse(url) else { return nil }
        guard let rhsResult = rhs.parse(lhsResult.0) else { return nil }
        return (rhsResult.0, flatten(lhsResult.match, rhsResult.match ))
    }
}

func printBoth<S1, S2>(_ lhs: RoutePattern<Any, S1>, _ rhs: RoutePattern<Any, S2>) -> Printer<Any> {
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
