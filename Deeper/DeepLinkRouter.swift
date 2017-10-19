//
//  DeepLinkRouter.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public class DeepLinkRouter<Handler: DeepLinkHandler> {
    weak private(set) var rootDeepLinkHandler: Handler?
    let scheme: String
    
    public typealias HandlerClosure = (URL, [DeepLinkPatternParameter: String]) -> Handler.Intent?
    var routesHandlers: [DeepLinkRoute: HandlerClosure] = [:]
    var routesPreference: [DeepLinkRoute] = []
    
    public init(scheme: String, rootDeepLinkHandler: Handler) {
        self.scheme = scheme
        self.rootDeepLinkHandler = rootDeepLinkHandler
    }
    
    public func add(routes: [DeepLinkRoute], handler: @escaping HandlerClosure) {
        routesPreference.append(contentsOf: routes)
        routes.forEach({ routesHandlers[$0] = handler })
    }
    
    public func canOpen(url: URL) -> Bool {
        return openURL(url) != nil
    }
    
    @discardableResult
    public func open(url: URL) -> Bool {
        guard let (_, intent) = openURL(url) else { return false }
        let deeplink = DeepLink(url: url, intent: intent)
        rootDeepLinkHandler?.open(deeplink: deeplink, animated: true) as Void?
        return true
    }
    
    func openURL(_ url: URL) -> (DeepLinkPatternMatcher.Result, Handler.Intent)? {
        guard url.scheme == scheme else { return nil }
        
        for route in routesPreference {
            let matcher = DeepLinkPatternMatcher(route: route, url: url)
            let result = matcher.match()
            if result.matched, let handler = routesHandlers[route], let intent = handler(url, result.params) {
                return (result, intent)
            }
        }
        return nil
    }
}
