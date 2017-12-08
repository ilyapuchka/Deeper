//
//  Router.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public class Router<Intent>: DeepLinkRouter {

    public private(set) var rootDeepLinkHandler: AnyDeepLinkHandler<Intent>?
    let scheme: String
    
    public typealias HandlerClosure = (URL, [DeepLinkPatternParameter: String]) -> Intent?
    var routesHandlers: [DeepLinkRoute: HandlerClosure] = [:]
    var routesPreference: [DeepLinkRoute] = []
    
    public init(scheme: String, rootDeepLinkHandler: AnyDeepLinkHandler<Intent>) {
        self.scheme = scheme
        self.rootDeepLinkHandler = rootDeepLinkHandler
    }

    public func add(routes: [DeepLinkRoute], handler: @escaping HandlerClosure) {
        add(routes: routes as [DeepLinkRouteConvertible], handler: handler)
    }

    public func add(routes: DeepLinkRoute..., handler: @escaping HandlerClosure) {
        add(routes: routes as [DeepLinkRouteConvertible], handler: handler)
    }

    public func add(routes: DeepLinkRouteConvertible..., handler: @escaping HandlerClosure) {
        add(routes: routes, handler: handler)
    }
    
    public func add(routes: [DeepLinkRouteConvertible], handler: @escaping HandlerClosure) {
        let routes = routes.map({ $0.route })
        routesPreference.append(contentsOf: routes)
        routes.forEach({ routesHandlers[$0] = handler })
    }
    
    public func openURL(_ url: URL) -> Intent? {
        guard url.scheme == scheme else { return nil }
        
        for route in routesPreference {
            let matcher = DeepLinkPatternMatcher(route: route, url: url)
            let result = matcher.match()
            if result.matched, let handler = routesHandlers[route], let intent = handler(url, result.params) {
                return intent
            }
        }
        return nil
    }
}
