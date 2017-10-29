//
//  DeepLinkHandlingTests.swift
//  DeeperTests
//
//  Created by Ilya Puchka on 29/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import XCTest
@testable import Deeper

class DeepLinkHandlingTests: XCTestCase {
    
    func testThatItDoesNotOpenURLWithWrongScheme() {
        let router = Router(scheme: "app", rootDeepLinkHandler: FinalHandler())
        router.add(routes: ["recipes"]) { _, _ in .action }
        XCTAssertFalse(router.canOpen(url: URL(string: "http://recipes")!))
    }
    
    private func routeURL<H: DeepLinkHandler>(handler: H) where H.Intent == Intent {
        let router = Router(scheme: "app", rootDeepLinkHandler: .init(handler))
        router.add(routes: ["recipes"]) { _, _ in .action }
        router.open(url: URL(string: "app://recipes")!)
    }
    
    func testDelayedDeepLinkHandling() {
        let handler = DelayedHandler()
        routeURL(handler: handler)
        
        XCTAssertTrue(handler.calledSideEffect)
        guard handler.states.count == 2,
            case .delayed? = handler.states.first,
            case .opened? = handler.states.last else {
                XCTFail("Invalid handling states: \(handler.states)")
                return
        }
    }
    
    func testOpenedDeepLinkHandling() {
        let handler = FinalHandler()
        routeURL(handler: handler)
        
        XCTAssertTrue(handler.calledSideEffect)
        guard handler.states.count == 1,
            case .opened? = handler.states.last else {
                XCTFail("Invalid handling states: \(handler.states)")
                return
        }
    }
    
    func testRejectedDeepLinkHandling() {
        let handler = RejecthHandler()
        routeURL(handler: handler)
        
        guard handler.states.count == 1,
            case .rejected? = handler.states.last else {
                XCTFail("Invalid handling states: \(handler.states)")
                return
        }
    }
    
    func testPassedThroughDeepLinkHandling() {
        let handler = PassThroughHandler()
        routeURL(handler: handler)
        
        XCTAssertTrue(handler.calledSideEffect)
        guard handler.states.count == 1,
            case .passedThrough? = handler.states.last else {
                XCTFail("Invalid handling states: \(handler.states)")
                return
        }
        XCTAssertTrue(handler.passedToHandler.calledSideEffect)
        guard handler.passedToHandler.states.count == 1,
            case .opened? = handler.passedToHandler.states.last else {
                XCTFail("Invalid handling states: \(handler.states)")
                return
        }
    }
}
