//
//  Configuration.swift
//  Deeper
//
//  Created by Ilya Puchka on 29/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

var clearDeeplinkHandling = true

public func configure(clearDeeplinkHandling _clearDeeplinkHandling: Bool = true, logger _logger: Logger? = Logger()) {
    clearDeeplinkHandling = _clearDeeplinkHandling
    logger = _logger
}

