//
//  Router.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 26/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public class Router<U>: DeepLinkRouter, CustomStringConvertible {
    public private(set) var rootDeepLinkHandler: AnyDeepLinkHandler<U>?

    public var routes: [(URL) -> U?] = []
    public var templates: [String] = []
    
    let scheme: String

    public init(scheme: String, rootDeepLinkHandler: AnyDeepLinkHandler<Intent>) {
        self.scheme = scheme
        self.rootDeepLinkHandler = rootDeepLinkHandler
    }

    public var description: String {
        return "\(type(of: self)):\n" + templates.filter({ !$0.isEmpty }).joined(separator: "\n")
    }
    
    public func openURL(_ url: URL) -> U? {
        guard url.scheme == scheme else { return nil }
        
        for route in routes {
            if let intent = route(url) { return intent }
        }
        return nil
    }

    @discardableResult
    func add(_ route: @escaping (URL) -> U?) -> Router {
        routes.append(route)
        return self
    }
    
    @discardableResult
    public func add(_ intent: U, _ route: String) -> Router {
        return add(intent, lit(route))
    }
    
    @discardableResult
    public func add<S: ClosedPatternState>(_ intent: U, _ route: RoutePattern<Void, S>) -> Router {
        add({ url in
            route.parse(routeComponents(from: url))
                .flatMap({ $0.rest.path.isEmpty ? intent : nil })
        })
        templates.append(route.template)
        return self
    }
    
    @discardableResult
    public func add(_ intent: U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<Void, Path> = route.map({ _ in () }, { _ in () })
        return add(intent, typedRoute)
    }

    @discardableResult
    public func add<A, S: ClosedPatternState>(_ intent: @escaping ((A)) -> U, _ route: RoutePattern<A, S>) -> Router {
        add({ url in
            route.parse(routeComponents(from: url))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(intent)
        })
        templates.append(route.template)
        return self
    }

    @discardableResult
    public func add<A>(_ intent: @escaping ((A)) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<A, Path> = route.map({ $0 as? A }, { $0 })
        return add(intent, typedRoute)
    }
    
    @discardableResult
    public func add<A, B, S: ClosedPatternState>(_ intent: @escaping ((A, B)) -> U, _ route: RoutePattern<(A, B), S>) -> Router {
        add({ url in
            route.parse(routeComponents(from: url))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(intent)
        })
        templates.append(route.template)
        return self
    }

    @discardableResult
    public func add<A, B>(_ intent: @escaping ((A, B)) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<(A, B), Path> = route.map({ $0 as? (A, B) }, { $0 })
        return add(intent, typedRoute)
    }

    @discardableResult
    public func add<A, B, C, S: ClosedPatternState>(_ intent: @escaping (A, B, C) -> U, _ route: RoutePattern<((A, B), C), S>) -> Router {
        add({ url in
            route.parse(routeComponents(from: url))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(flatten)
                .map(intent)
        })
        templates.append(route.template)
        return self
    }
    
    @discardableResult
    public func add<A, B, C>(_ intent: @escaping (A, B, C) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<((A, B), C), Path> = route.map({ $0 as? ((A, B), C) }, { $0 })
        return add(intent, typedRoute)
    }

    @discardableResult
    public func add<A, B, C, D, S: ClosedPatternState>(_ intent: @escaping (A, B, C, D) -> U, _ route: RoutePattern<(((A, B), C), D), S>) -> Router {
        add({ url in
            route.parse(routeComponents(from: url))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(flatten)
                .map(intent)
        })
        templates.append(route.template)
        return self
    }

    @discardableResult
    public func add<A, B, C, D>(_ intent: @escaping (A, B, C, D) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<(((A, B), C), D), Path> = route.map({ $0 as? (((A, B), C), D) }, { $0 })
        return add(intent, typedRoute)
    }
    
    @discardableResult
    public func add<A, B, C, D, E, S: ClosedPatternState>(_ intent: @escaping (A, B, C, D, E) -> U, _ route: RoutePattern<((((A, B), C), D), E), S>) -> Router {
        add({ url in
            route.parse(routeComponents(from: url))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(flatten)
                .map(intent)
        })
        templates.append(route.template)
        return self
    }
    
    @discardableResult
    public func add<A, B, C, D, E>(_ intent: @escaping (A, B, C, D, E) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<((((A, B), C), D), E), Path> = route.map({ $0 as? ((((A, B), C), D), E) }, { $0 })
        return add(intent, typedRoute)
    }

    @discardableResult
    public func add<A, B, C, D, E, F, S: ClosedPatternState>(_ intent: @escaping (A, B, C, D, E, F) -> U, _ route: RoutePattern<(((((A, B), C), D), E), F), S>) -> Router {
        add({ url in
            route.parse(routeComponents(from: url))
                .flatMap({ $0.rest.path.isEmpty ? $0.match : nil })
                .map(flatten)
                .map(intent)
        })
        templates.append(route.template)
        return self
    }
    
    @discardableResult
    public func add<A, B, C, D, E, F>(_ intent: @escaping (A, B, C, D, E, F) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<(((((A, B), C), D), E), F), Path> = route.map({ $0 as? (((((A, B), C), D), E), F) }, { $0 })
        return add(intent, typedRoute)
    }
    
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

func parenthesize<A, B, C>(_ t: (A, B, C)) -> ((A, B), C) {
    return ((t.0, t.1), t.2)
}

func parenthesize<A, B, C, D>(_ t: (A, B, C, D)) -> (((A, B), C), D) {
    return (((t.0, t.1), t.2), t.3)
}

func parenthesize<A, B, C, D, E>(_ t: (A, B, C, D, E)) -> ((((A, B), C), D), E) {
    return ((((t.0, t.1), t.2), t.3), t.4)
}

func parenthesize<A, B, C, D, E, F>(_ t: (A, B, C, D, E, F)) -> (((((A, B), C), D), E), F) {
    return (((((t.0, t.1), t.2), t.3), t.4), t.5)
}

extension Router {

    public func url<S: ClosedPatternState>(route: RoutePattern<Any, S>, values: Any) -> URL? {
        if let values = values as? (Any, Any) {
            return route.print(values).flatMap(url(from:))
        } else if let values = values as? (Any, Any, Any) {
            return route.print(parenthesize(values)).flatMap(url(from:))
        } else if let values = values as? (Any, Any, Any, Any) {
            return route.print(parenthesize(values)).flatMap(url(from:))
        } else if let values = values as? (Any, Any, Any, Any, Any) {
            return route.print(parenthesize(values)).flatMap(url(from:))
        } else if let values = values as? (Any, Any, Any, Any, Any, Any) {
            return route.print(parenthesize(values)).flatMap(url(from:))
        }
        return route.print(values).flatMap(url(from:))
    }

    public func url<A, S: ClosedPatternState>(route: RoutePattern<A, S>, values: A) -> URL? {
        return route.print(values).flatMap(url(from:))
    }

    public func url<A, B, S: ClosedPatternState>(route: RoutePattern<(A, B), S>, values: (A, B)) -> URL? {
        return route.print(values).flatMap(url(from:))
    }

    public func url<A, B, C, S: ClosedPatternState>(route: RoutePattern<((A, B), C), S>, values: (A, B, C)) -> URL? {
        return route.print(parenthesize(values)).flatMap(url(from:))
    }

    public func url<A, B, C, D, S: ClosedPatternState>(route: RoutePattern<(((A, B), C), D), S>, values: (A, B, C, D)) -> URL? {
        return route.print(parenthesize(values)).flatMap(url(from:))
    }

    public func url<A, B, C, D, E, S: ClosedPatternState>(route: RoutePattern<((((A, B), C), D), E), S>, values: (A, B, C, D, E)) -> URL? {
        return route.print(parenthesize(values)).flatMap(url(from:))
    }

    public func url<A, B, C, D, E, F, S: ClosedPatternState>(route: RoutePattern<(((((A, B), C), D), E), F), S>, values: (A, B, C, D, E, F)) -> URL? {
        return route.print(parenthesize(values)).flatMap(url(from:))
    }

    func url(from routeComponents: RouteComponents) -> URL? {
        guard !routeComponents.path.isEmpty else { return nil }
        
        var components = URLComponents()
        components.scheme = scheme
        components.host = routeComponents.path.first
        components.path = "/\(routeComponents.path.suffix(from: 1).joined(separator: "/"))"
        if !routeComponents.query.isEmpty {
            components.queryItems = routeComponents.query.map({ URLQueryItem(name: $0, value: $1) })
        }
        
        return components.url
    }
}

public func routeComponents(from url: URL) -> RouteComponents {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return ([], [:])
    }
    let path = [components.host].flatMap({ $0 }) + components.path.components(separatedBy: "/").filter({ !$0.isEmpty })
    let query = components.queryItems?.filter({ $0.value != nil }).map({ ($0.name, $0.value!) })
    return (path, Dictionary(query ?? [], uniquingKeysWith: { $1 }))
}


