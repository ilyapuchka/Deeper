//
//  DeepLinkHandler.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public protocol DeepLinkHandler: class {
    associatedtype Intent
    // stores the current state of deeplink handling
    var deeplinkHandling: DeepLinkHandling<Intent>? { get set }
    // attempts to handle deeplink and returns next state
    func open(deeplink: DeepLink<Intent>, animated: Bool) -> DeepLinkHandling<Intent>
}

extension DeepLinkHandler {
    
    /// Attempts to handle deeplink and updates its state.
    /// You should call this method instead of `open(deeplink:animated:) -> DeepLinkHandling<Intent>`,
    /// but you usually don't need to do that as passedThrough state will call it on returned handler itself
    public func open(deeplink: DeepLink<Intent>, animated: Bool) {
        let result = open(deeplink: deeplink, animated: animated)
        logger.log(deeplink: deeplink, result: result, handler: self)
        deeplinkHandling = result
        
        switch result {
        case let .opened(_, sideEffect?):
            sideEffect(animated)
        case let .delayed(_, _, sideEffect?):
            sideEffect(animated)
            return
        case let .passedThrough(deeplink, sideEffect?):
            let handler = sideEffect(animated)
            handler.open(deeplink: deeplink, animated: animated) as Void
        default: break
        }
    }
    
    /// Call to complete deeplink handling if it was delayed
    public func complete(deeplinkHandling: DeepLinkHandling<Intent>?) {
        if case let .delayed(deeplink, animated, _)? = deeplinkHandling {
            open(deeplink: deeplink, animated: animated) as Void
        }
    }
}

open class AnyDeepLinkHandler<Intent>: DeepLinkHandler {
    
    open var deeplinkHandling: DeepLinkHandling<Intent>?
    
    private let _open: (DeepLink<Intent>, Bool) -> DeepLinkHandling<Intent>
    
    public init() {
        guard type(of: self) != AnyDeepLinkHandler<Intent>.self else {
            fatalError("Use init(_:) to create AnyDeepLinkHandler that wraps another handler")
        }
        self._open = { _, _ in
            fatalError("Do not call `super.open(deeplink:animated:) -> DeepLinkHandling<Intent>` when inheriting from AnyDeepLinkHandler")
        }
    }
    
    /// Use this initialiser to wrap instances that are not subclasses of `AnyDeepLinkHandler`.
    public init<Handler: DeepLinkHandler>(_ handler: Handler) where Handler.Intent == Intent {
        self._open = {
            let handling = handler.open(deeplink: $0, animated: $1)
            switch handling {
            case let .delayed(deeplink, animated, effect):
                return .delayed(deeplink, animated, effect)
            case let .opened(deeplink, effect):
                return .opened(deeplink, effect)
            case let .passedThrough(deeplink, effect):
                return .passedThrough(deeplink, effect.map({ effect in { AnyDeepLinkHandler(effect($0)) }}))
            case let .rejected(deeplink, effect):
                return .rejected(deeplink, effect)
            }
        }
    }
    
    open func open(deeplink: DeepLink<Intent>, animated: Bool) -> DeepLinkHandling<Intent> {
        return _open(deeplink, animated)
    }
}
