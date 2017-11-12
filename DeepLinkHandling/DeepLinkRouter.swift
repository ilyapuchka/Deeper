//
//  DeepLinkRouter.swift
//  Deeper
//
//  Created by Ilya Puchka on 29/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol DeepLinkRouter {
    /// Type of intent handled by router
    associatedtype Intent
    
    /// Reference to root deeplink handler
    var rootDeepLinkHandler: AnyDeepLinkHandler<Intent>? { get }
    
    /// Try to parse url to Intent
    func openURL(_ url: URL) -> Intent?
}

extension DeepLinkRouter {
    
    /// Returns true if url can be parsed to Intent
    public func canOpen(url: URL) -> Bool {
        return openURL(url) != nil
    }
    
    /// Return true if url can be parsed to Intent and opens it with `rootDeepLinkHandler`
    @discardableResult
    public func open(url: URL) -> Bool {
        guard let intent = openURL(url) else { return false }
        let deeplink = DeepLink(url: url, intent: intent)
        rootDeepLinkHandler?.open(deeplink: deeplink, animated: true) as Void?
        return true
    }

}
