//
//  Logger.swift
//  Deeper
//
//  Created by Ilya Puchka on 29/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

var logger: Logger? = Logger()

open class Logger {
    
    public init() {}
    
    open func log<Handler: DeepLinkHandler>(deeplink: DeepLink<Handler.Intent>, result: DeepLinkHandling<Handler.Intent>, handler: Handler) {
        print(result)
    }
    
}
