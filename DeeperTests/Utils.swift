//
//  Utils.swift
//  DeeperTests
//
//  Created by Ilya Puchka on 10/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//
import Deeper

enum Intent {
    case action
}

class DelayedHandler: DeepLinkHandler {
    var deeplinkHandling: DeepLinkHandling<Intent>? {
        didSet {
            states.append(deeplinkHandling!)
        }
    }
    var calledSideEffect: Bool = false
    var states: [DeepLinkHandling<Intent>] = []
    
    func open(deeplink: DeepLink<Intent>, animated: Bool) -> DeepLinkHandling<Intent> {
        if calledSideEffect {
            return .opened(deeplink, nil)
        }
        return DeepLinkHandling<Intent>.delayed(deeplink, animated, { [unowned self] _ in
            self.calledSideEffect = true
            self.complete(deeplinkHandling: self.deeplinkHandling)
        })
    }
}

class PassThroughHandler: DeepLinkHandler {
    var deeplinkHandling: DeepLinkHandling<Intent>? {
        didSet {
            states.append(deeplinkHandling!)
        }
    }
    var calledSideEffect: Bool = false
    var states: [DeepLinkHandling<Intent>] = []
    
    let passedToHandler = FinalHandler()
    
    func open(deeplink: DeepLink<Intent>, animated: Bool) -> DeepLinkHandling<Intent> {
        return DeepLinkHandling<Intent>.passedThrough(deeplink, { [unowned self] _ in
            self.calledSideEffect = true
            return self.passedToHandler
        })
    }
}

class FinalHandler: AnyDeepLinkHandler<Intent> {
    override var deeplinkHandling: DeepLinkHandling<Intent>? {
        didSet {
            states.append(deeplinkHandling!)
        }
    }
    var calledSideEffect: Bool = false
    var states: [DeepLinkHandling<Intent>] = []
    
    override init() {
        super.init()
    }
    
    override func open(deeplink: DeepLink<Intent>, animated: Bool) -> DeepLinkHandling<Intent> {
        return .opened(deeplink, { [unowned self] _ in
            self.calledSideEffect = true
        })
    }
}

class RejecthHandler: DeepLinkHandler {
    var deeplinkHandling: DeepLinkHandling<Intent>? {
        didSet {
            states.append(deeplinkHandling!)
        }
    }
    var states: [DeepLinkHandling<Intent>] = []
    
    func open(deeplink: DeepLink<Intent>, animated: Bool) -> DeepLinkHandling<Intent> {
        return .rejected(deeplink, nil)
    }
}
