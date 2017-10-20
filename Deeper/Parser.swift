//
//  Parser.swift
//  Deeper
//
//  Created by Ilya Puchka on 20/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

func parsePattern(_ format: String) -> [DeepLinkPathPattern] {
    var format = format
    if let queryStart = format.index(of: "?") {
        format = String(format.prefix(upTo: queryStart))
    }
    return parsePatterns([format])
}

func parsePatterns(_ formatComponents: [String]) -> [DeepLinkPathPattern] {
    var formatComponents = formatComponents
    return formatComponents.reduce([], { (acc, component) -> [DeepLinkPathPattern] in
        if let parsed = parseAny(formatComponents)
            ?? parseOr(formatComponents)
            ?? parsePaths(formatComponents)
            ?? parseMaybe(formatComponents)
            ?? parseParam(formatComponents)
            ?? parseString(formatComponents) {
            formatComponents = parsed.1
            return acc + parsed.0
        } else {
            return acc
        }
    })
}

typealias Parser = ([String]) -> ([DeepLinkPathPattern], [String])?

func parsePaths(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    guard let component = formatComponents.first else { return nil }
    let components = component.components(separatedBy: "/", excludingDelimiterBetween: ("(", ")"))
    if components.count > 1 {
        return (components.flatMap({ parsePatterns([$0]) }), Array(formatComponents.dropFirst()))
    } else {
        return nil
    }
}

func parseAny(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    if formatComponents.first == "*" {
        return ([.any], Array(formatComponents.dropFirst()))
    }
    return nil
}

func parseOr(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    guard var component = formatComponents.first else { return nil }
    if component.hasPrefix("(") && component.hasSuffix(")") {
        component = String(component.dropFirst().dropLast())
    }
    let orComponents = component.components(separatedBy: "|", excludingDelimiterBetween: ("(", ")"))
    if orComponents.count > 1 {
        let lhs = parsePatterns([orComponents[0]])
        let rhs = parsePatterns([orComponents.dropFirst().joined(separator: "|")])
        return ([.or(DeepLinkRoute(pattern: lhs), DeepLinkRoute(pattern: rhs))], Array(formatComponents.dropFirst()))
    }
    return nil
}

func parseMaybe(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    if var component = formatComponents.first, component.trimPrefix("("), component.trimSuffix(")") {
        let parsed = parsePatterns([component])
        return ([.maybe(DeepLinkRoute(pattern: parsed))], Array(formatComponents.dropFirst()))
    }
    return nil
}

func parseParam(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    if let typed = parseNumParam(formatComponents)
        ?? parseStringParam(formatComponents)
        ?? parseBoolParam(formatComponents) {
        return typed
    }
    
    if var component = formatComponents.first, component.trimPrefix(":") {
        return ([.param(DeepLinkPatternParameter(component))], Array(formatComponents.dropFirst()))
    }
    return nil
}

func parseNumParam(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    if var component = formatComponents.first,
        component.trimPrefix(":num("), component.trimSuffix(")") {
        return ([.param(DeepLinkPatternParameter(component, type: .num))], Array(formatComponents.dropFirst()))
    }
    return nil
}

func parseStringParam(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    if var component = formatComponents.first,
        component.trimPrefix(":str("), component.trimSuffix(")") {
        return ([.param(DeepLinkPatternParameter(component, type: .str))], Array(formatComponents.dropFirst()))
    }
    return nil
}

func parseBoolParam(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    if var component = formatComponents.first,
        component.trimPrefix(":bool("), component.trimSuffix(")") {
        return ([.param(DeepLinkPatternParameter(component, type: .bool))], Array(formatComponents.dropFirst()))
    }
    return nil
}

func parseString(_ formatComponents: [String]) -> ([DeepLinkPathPattern], [String])? {
    if let component = formatComponents.first {
        return ([.string(component)], Array(formatComponents.dropFirst()))
    }
    return nil
}
