//
//  Deeper.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 26/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public enum Either<A, B> {
    case left(A), right(B)
}

public typealias RouteComponents = (path: [String], query: [String: String])

public protocol PatternState {}
public protocol ClosedPatternState: PatternState {} // pattern is complete
public protocol OpenPatternState: PatternState {} // pattern requires subsequent pattern to become closed

public protocol ClosedPathPatternState: ClosedPatternState {}
public enum Path: ClosedPathPatternState {} // somewhere in the path
public enum Query: ClosedPatternState {} // query started

public struct RoutePattern<A/*pattern type*/, S: PatternState> {
    public let parse: Parser<A> // parses path components exctracting underlying type of pattern
    public let print: Printer<A> // converts pattern with passed in value to template component
    public let template: String
    
    func map<S>(_ iso: PartialIso<A, Any>) -> RoutePattern<Any, S> {
        return .init(parse: {
            guard let result = self.parse($0) else { return nil }
            return (result.0, result.1)
        }, print: {
            guard let value = iso.unapply($0) else { return nil }
            return self.print(value)
        }, template: template)
    }

}

// converts generic type to it's string representation, removing Optional and Either wrappers
func typeKey<A>(_ a: A.Type) -> String {
    let typeString = "\(a)"
    let typeKey: String
    if typeString.contains("Optional<") {
        typeKey = "(\(typeString))"
            .replacingOccurrences(of: "Optional<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .lowercased()
    } else if typeString.contains("Either<") {
        typeKey = "\(typeString)"
            .replacingOccurrences(of: "Either<", with: "")
            .replacingOccurrences(of: ", ", with: "|")
            .replacingOccurrences(of: ">", with: "")
            .lowercased()
    } else {
        typeKey = typeString.lowercased()
    }
    
    return typeKey
}

// drops either lhs or rhs if they are Void
func flatten(_ lhs: Any, _ rhs: Any) -> Any {
    if lhs is Void, rhs is Void {
        return ()
    } else if lhs is Void {
        return rhs
    } else if rhs is Void {
        return lhs
    } else {
        return (lhs, rhs)
    }
}
