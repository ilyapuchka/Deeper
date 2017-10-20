//
//  Router.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 26/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public class Router<U>: CustomStringConvertible {
    
    public var routes: [(URLRequest) -> U?] = []
    public var templates: [String] = []
    
    public init() {}
    
    public var description: String {
        return "\(type(of: self)):\n" + templates.filter({ !$0.isEmpty }).joined(separator: "\n")
    }
    
    public func match(_ request: URLRequest) -> U? {
        for route in routes {
            if let intent = route(request) { return intent }
        }
        return nil
    }

    @discardableResult
    func add(_ route: @escaping (URLRequest) -> U?) -> Router {
        routes.append(route)
        return self
    }
    
    @discardableResult
    public func add(_ intent: U, _ route: String) -> Router {
        return add(intent, (lit(route) as RoutePattern<Void, Path>))
    }
    
    @discardableResult
    public func add<S: ClosedPatternState>(_ intent: U, _ route: RoutePattern<Void, S>) -> Router {
        add({ request in
            route.parse(routeComponents(from: request))
                .flatMap({ $0.rest.path.isEmpty ? intent : nil })
        })
        templates.append(route.template)
        return self
    }
    
    @discardableResult
    public func add<A, S: ClosedPatternState>(_ intent: @escaping (A) -> U, _ route: RoutePattern<A, S>) -> Router {
        add({ request in
            route.parse(routeComponents(from: request))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(intent)
        })
        templates.append(route.template)
        return self
    }
    
    @discardableResult
    public func add<A, B, C, S: ClosedPatternState>(_ intent: @escaping (A, B, C) -> U, _ route: RoutePattern<((A, B), C), S>) -> Router {
        add({ request in
            route.parse(routeComponents(from: request))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(flatten)
                .map(intent)
        })
        templates.append(route.template)
        return self
    }
    
    
    @discardableResult
    public func add<A, B, C, D, S: ClosedPatternState>(_ intent: @escaping (A, B, C, D) -> U, _ route: RoutePattern<(((A, B), C), D), S>) -> Router {
        add({ request in
            route.parse(routeComponents(from: request))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(flatten)
                .map(intent)
        })
        templates.append(route.template)
        return self
    }
    
    @discardableResult
    public func add<A, B, C, D, E, S: ClosedPatternState>(_ intent: @escaping (A, B, C, D, E) -> U, _ route: RoutePattern<((((A, B), C), D), E), S>) -> Router {
        add({ request in
            route.parse(routeComponents(from: request))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(flatten)
                .map(intent)
        })
        templates.append(route.template)
        return self
    }
    
}

precedencegroup RoutesPrecedence {
    lowerThan: MultiplicationPrecedence
    associativity: right
}

func flatten<A, B, C>(_ t: ((A, B), C)) -> (A, B, C) {
    return (t.0.0, t.0.1, t.1)
}

func flatten<A, B, C, D>(_ t: (((A, B), C), D)) -> (A, B, C, D) {
    return (t.0.0.0, t.0.0.1, t.0.1, t.1)
}

func flatten<A, B, C, D, E>(_ t: ((((A, B), C), D), E)) -> (A, B, C, D, E) {
    return (t.0.0.0.0, t.0.0.0.1, t.0.0.1, t.0.1, t.1)
}

func flatten<A, B, C, D, E, F>(_ t: (((((A, B), C), D), E), F)) -> (A, B, C, D, E, F) {
    return (t.0.0.0.0.0, t.0.0.0.0.1, t.0.0.0.1, t.0.0.1, t.0.1, t.1)
}

private func routeComponents(from request: URLRequest) -> RouteComponents {
    guard let components = request.url.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }) else {
        return ([], [:])
    }
    let path = [components.host].flatMap({ $0 }) + components.path.components(separatedBy: "/").filter({ !$0.isEmpty })
    let query = components.queryItems?.filter({ $0.value != nil }).map({ ($0.name, $0.value!) })
    return (path, Dictionary(query ?? [], uniquingKeysWith: { $1 }))
}


