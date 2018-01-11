//
//  Router.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 26/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol Route: Equatable {
    func deconstruct<A>(_ constructor: (A) -> Self) -> A?
}

extension Route {
    /// Matches route with passed in constructor and its values with `A`, returns values if matched.
    /// To be used in `deconstruct` implementation.
    public func extract<A>(_ constructor: (A) -> Self, _ values: Any?) -> A? {
        guard let values = values as? A else { return nil }
        guard self == constructor(values) else { return nil }
        return values
    }
}

public class Router<U: Route>: DeepLinkRouter, CustomStringConvertible {
    public let scheme: String
    public let rootDeepLinkHandler: AnyDeepLinkHandler<U>?
    
    private var route: RoutePattern<U, Path>?

    public init(scheme: String, rootDeepLinkHandler: AnyDeepLinkHandler<Intent>) {
        self.scheme = scheme
        self.rootDeepLinkHandler = rootDeepLinkHandler
    }

    public var description: String {
        return "\(type(of: self)):\n[\(route?.template ?? "")]"
    }
    
    public func intent(for url: URL) -> U? {
        guard
            let components = url.routeComponents,
            url.scheme == scheme,
            let result = route?.parse(components),
            result.rest.path.isEmpty
            else { return nil }
        
        return result.match
    }

    private func add(_ route: RoutePattern<U, Path>) -> Router {
        self.route = self.route.map({ oldValue in
            .init(parse: { oldValue.parse($0) ?? route.parse($0) },
                  print: { oldValue.print($0) ?? route.print($0) },
                  template: "\(oldValue.template)\n\(route.template)")
        }) ?? route
        return self
    }
    
    @discardableResult
    public func add(_ intent: U, route: String) -> Router {
        return add(intent, route: lit(route))
    }
    
    @discardableResult
    public func add<S: ClosedPatternState>(_ intent: @escaping @autoclosure () -> U, route: RoutePattern<Void, S>) -> Router {
        return add(route.map({ intent() }, { $0.deconstruct(intent) }))
    }
    
    @discardableResult
    public func add(_ intent: U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<Void, Path> = route.map({ _ in () }, { _ in () })
        return add(intent, route: typedRoute)
    }

    @discardableResult
    public func add<A, S: ClosedPatternState>(_ intent: @escaping ((A)) -> U, route: RoutePattern<A, S>) -> Router {
        return add(route.map({ intent($0) }, { $0.deconstruct(intent) }))
    }

    @discardableResult
    public func add<A>(_ intent: @escaping ((A)) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<A, Path> = route.map({ $0 as? A }, { $0 })
        return add(intent, route: typedRoute)
    }
    
    @discardableResult
    public func add<A, B, S: ClosedPatternState>(_ intent: @escaping ((A, B)) -> U, route: RoutePattern<(A, B), S>) -> Router {
        return add(route.map({ intent($0) }, { $0.deconstruct(intent) }))
    }

    @discardableResult
    public func add<A, B>(_ intent: @escaping ((A, B)) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<(A, B), Path> = route.map({ $0 as? (A, B) }, { $0 })
        return add(intent, route: typedRoute)
    }

    @discardableResult
    public func add<A, B, C, S: ClosedPatternState>(_ intent: @escaping ((A, B, C)) -> U, route: RoutePattern<((A, B), C), S>) -> Router {
        return add(route.map({ intent(flatten($0)) }, { $0.deconstruct(intent).map(parenthesize) }))
    }
    
    @discardableResult
    public func add<A, B, C>(_ intent: @escaping (A, B, C) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<((A, B), C), Path> = route.map({ $0 as? ((A, B), C) }, { $0 })
        return add(intent, route: typedRoute)
    }

    @discardableResult
    public func add<A, B, C, D, S: ClosedPatternState>(_ intent: @escaping ((A, B, C, D)) -> U, route: RoutePattern<(((A, B), C), D), S>) -> Router {
        return add(route.map({ intent(flatten($0)) }, { $0.deconstruct(intent).map(parenthesize) }))
    }

    @discardableResult
    public func add<A, B, C, D>(_ intent: @escaping (A, B, C, D) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<(((A, B), C), D), Path> = route.map({ $0 as? (((A, B), C), D) }, { $0 })
        return add(intent, route: typedRoute)
    }
    
    @discardableResult
    public func add<A, B, C, D, E, S: ClosedPatternState>(_ intent: @escaping ((A, B, C, D, E)) -> U, route: RoutePattern<((((A, B), C), D), E), S>) -> Router {
        return add(route.map({ intent(flatten($0)) }, { $0.deconstruct(intent).map(parenthesize) }))
    }
    
    @discardableResult
    public func add<A, B, C, D, E>(_ intent: @escaping (A, B, C, D, E) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<((((A, B), C), D), E), Path> = route.map({ $0 as? ((((A, B), C), D), E) }, { $0 })
        return add(intent, route: typedRoute)
    }

    @discardableResult
    public func add<A, B, C, D, E, F, S: ClosedPatternState>(_ intent: @escaping ((A, B, C, D, E, F)) -> U, route: RoutePattern<(((((A, B), C), D), E), F), S>) -> Router {
        return add(route.map({ intent(flatten($0)) }, { $0.deconstruct(intent).map(parenthesize) }))
    }
    
    @discardableResult
    public func add<A, B, C, D, E, F>(_ intent: @escaping (A, B, C, D, E, F) -> U, format: String) -> Router {
        guard let route = format.routePattern else { return self }
        let typedRoute: RoutePattern<(((((A, B), C), D), E), F), Path> = route.map({ $0 as? (((((A, B), C), D), E), F) }, { $0 })
        return add(intent, route: typedRoute)
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

    public func url(for intent: U) -> URL? {
        return self.route?.print(intent).flatMap(url(from:))
    }
    
    public func open(urlFor intent: U) -> Bool {
        guard let url = url(for: intent) else { return false }
        let deeplink = DeepLink(url: url, intent: intent)
        rootDeepLinkHandler?.open(deeplink: deeplink, animated: true) as Void?
        return true
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

extension URL {

    public var routeComponents: RouteComponents? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        
        let path = [components.host].flatMap({ $0 }) + components.path.components(separatedBy: "/").filter({ !$0.isEmpty })
        let query = components.queryItems?.filter({ $0.value != nil }).map({
            (
                $0.name.removingPercentEncoding ?? $0.name,
                $0.value!.removingPercentEncoding ?? $0.value!
            )
        })
        return (path.map({ $0.removingPercentEncoding ?? $0 }), Dictionary(query ?? [], uniquingKeysWith: { $1 }))
    }

}


