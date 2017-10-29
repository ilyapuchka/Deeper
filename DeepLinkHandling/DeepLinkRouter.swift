//
//  DeepLinkRouter.swift
//  Deeper
//
//  Created by Ilya Puchka on 29/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

public protocol DeepLinkRouter {
    associatedtype Intent
    
    var rootDeepLinkHandler: AnyDeepLinkHandler<Intent>? { get }
    
    func openURL(_ url: URL) -> Intent?
}

extension DeepLinkRouter {
    
    public func canOpen(url: URL) -> Bool {
        return openURL(url) != nil
    }
    
    @discardableResult
    public func open(url: URL) -> Bool {
        guard let intent = openURL(url) else { return false }
        let deeplink = DeepLink(url: url, intent: intent)
        rootDeepLinkHandler?.open(deeplink: deeplink, animated: true) as Void?
        return true
    }

}
