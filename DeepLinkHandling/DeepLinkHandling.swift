//
//  DeepLinkHandling.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public enum DeepLinkHandling<Intent>: CustomStringConvertible {
    
    /// Return this state if deeplink successfully handled
    case opened(DeepLink<Intent>, ((Bool) -> Void)?)
    
    /// Return this state if deeplink was rejected because it can't be handeled, with optional error
    case rejected(DeepLink<Intent>, Error?)
    
    /// Return this state if deeplink handling delayed because more data is needed
    case delayed(DeepLink<Intent>, Bool, ((Bool) -> Void)?)
    
    /// Return this state if deeplink was passed through to some other handler
    case passedThrough(DeepLink<Intent>, ((Bool) -> AnyDeepLinkHandler<Intent>)?)
    
    public var description: String {
        switch self {
        case .opened(let deeplink, _):
            return "Opened deeplink \(deeplink)"
        case .rejected(let deeplink, let reason):
            return "Rejected deeplink \(deeplink) for reason : \(reason?.localizedDescription ?? "unknown")"
        case .delayed(let deeplink, _, _):
            return "Delayed deeplink \(deeplink)"
        case .passedThrough(let deeplink, _):
            return "Passed through deeplink \(deeplink))"
        }
    }
    
}
