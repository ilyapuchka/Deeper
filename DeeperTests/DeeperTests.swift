//
//  DeeperTests.swift
//  DeeperTests
//
//  Created by Ilya Puchka on 28/09/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import XCTest
@testable import Deeper

extension DeepLinkPatternParameter {
    static let recipeId = DeepLinkPatternParameter("recipeId")
    static let menuId = DeepLinkPatternParameter.num("menuId")
}

extension DeepLinkRoute {
    static let recipes = DeepLinkRoute("recipes")
}

class DeeperTests: XCTestCase {
    
    func testThatPatternMatchesString() {
        var route: DeepLinkRoute
        var url: URL
        
        route = "recipes"
        url = URL(string: "http://recipes")!
        XCTAssertTrue(route.match(url: url).0)
        
        url = URL(string: "http://recipe")!
        XCTAssertFalse(route.match(url: url).0)

        url = URL(string: "http://recipe/archive")!
        XCTAssertFalse(route.match(url: url).0)

        route = "recipes/archive"
        url = URL(string: "http://recipes/archive")!
        XCTAssertTrue(route.match(url: url).0)
        
        url = URL(string: "http://recipes/archives")!
        XCTAssertFalse(route.match(url: url).0)

        url = URL(string: "http://recipes")!
        XCTAssertFalse(route.match(url: url).0)
    }

    func testThatPatternMatchesParameter() {
        var route: DeepLinkRoute
        var url: URL

        // have to use empty string as there is no convertion between param and pattern,
        // though this pattern is not likely to be used in real scenarios
        route = "" / .recipeId
        url = URL(string: "http://123")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])

        route = .recipes / .menuId / .recipeId
        url = URL(string: "http://recipes/123/456")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.menuId: "123", .recipeId: "456"])

        url = URL(string: "http://recipes/abc/456")!
        XCTAssertFalse(route.match(url: url).0)

        url = URL(string: "http://recipe/123")!
        XCTAssertFalse(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [:])

        route = .recipes / ":num()" / .recipeId
        url = URL(string: "http://recipes/123/456")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "456"])

        route = .recipeId / .recipes
        url = URL(string: "http://123/recipes")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])

        url = URL(string: "http://123/recipe")!
        XCTAssertFalse(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [:])
    }
    
    func testThatPatternMatchesCondition() {
        var route: DeepLinkRoute
        var url: URL

        route = "recipe" | .recipes

        url = URL(string: "http://recipe")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipes")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipes/archive")!
        XCTAssertFalse(route.match(url: url).0)

        route = ("recipe" | "recipes") / "archive"
        
        url = URL(string: "http://recipe/archive")!
        XCTAssertTrue(route.match(url: url).0)
        
        url = URL(string: "http://recipes/archive")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipes/archives")!
        XCTAssertFalse(route.match(url: url).0)

        route = ("recipe" | "recipes" | "recipes" / "archive") / .recipeId
        
        url = URL(string: "http://recipe/123")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])

        url = URL(string: "http://recipes/archive/123")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])

        url = URL(string: "http://recipes/archive/id/123")!
        XCTAssertFalse(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [:])

        url = URL(string: "http://recipes/123")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])

        url = URL(string: "http://recipes/all/123")!
        XCTAssertFalse(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [:])

        route = (("recipe" / .recipeId) | ("recipes" / .recipeId / "details"))
        
        url = URL(string: "http://recipe/123")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])

        url = URL(string: "http://recipes/123/details")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])
    }
    
    func testThatPatternMatchesMaybe() {
        var route: DeepLinkRoute
        var url: URL
        
        route = "recipe" / "(details)"

        url = URL(string: "http://recipe/details")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe/archive")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe")!
        XCTAssertFalse(route.match(url: url).0)
        
        route = "recipe" / .maybe("details" / .recipeId)
        
        url = URL(string: "http://recipe/details/123")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])
        
        url = URL(string: "http://recipe/details")!
        XCTAssertTrue(route.match(url: url).0)
    }

    func testThatPatternMatchesAny() {
        var route: DeepLinkRoute
        var url: URL

        route = "recipe" / .any
        
        url = URL(string: "http://recipe/123")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe")!
        XCTAssertFalse(route.match(url: url).0)

        route = .any / "recipe"
        
        url = URL(string: "http://some/recipe")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe")!
        XCTAssertFalse(route.match(url: url).0)

        route = .recipeId / .any / "recipe"
        
        url = URL(string: "http://123/recipe/recipe")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])
        
        url = URL(string: "http://123/recipe")!
        XCTAssertFalse(route.match(url: url).0)

        route = "recipe" / .any / "details"

        url = URL(string: "http://recipe/archive/details")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe/archive/123/details")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe/details")!
        XCTAssertFalse(route.match(url: url).0)
        
        url = URL(string: "http://recipe/archive/details/123")!
        XCTAssertFalse(route.match(url: url).0)

        route = "recipe" / .any / "details" / .any

        url = URL(string: "http://recipe/archive/details/123")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe/archive/details")!
        XCTAssertFalse(route.match(url: url).0)

        url = URL(string: "http://recipe/archive")!
        XCTAssertFalse(route.match(url: url).0)

        route = "recipe" / .any / ("details" / "recipe" | "view") / .any
        
        url = URL(string: "http://recipe/archive/details/recipe/123")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe/archive/view/123")!
        XCTAssertTrue(route.match(url: url).0)

        url = URL(string: "http://recipe/archive/details/123")!
        XCTAssertFalse(route.match(url: url).0)

        url = URL(string: "http://recipe/archive/overview/123")!
        XCTAssertFalse(route.match(url: url).0)

        route = "recipe" / .any / "details" / .recipeId
        
        url = URL(string: "http://recipe/archive/details/123")!
        XCTAssertTrue(route.match(url: url).0)
        XCTAssertEqual(route.match(url: url).1, [.recipeId: "123"])
        
        route = "recipe" / .any / .recipeId
        
        url = URL(string: "http://recipe/archive/details/123")!
        XCTAssertFalse(route.match(url: url).0, "any can be used only in the end or between two string patterns")
        
        route = "recipe" / .any / .any
        url = URL(string: "http://recipe/archive/details/123")!
        XCTAssertFalse(route.match(url: url).0, "can't have two any next to each other")
    }
    
    func testStringToPatternConversion() {
        let pattern = "(recipe|recipes|recipes/archive)/*/details/(info)/:num(menuId)/:recipeId".pattern
        let expectedPattern: [DeepLinkPattern] = [
            DeepLinkPattern.or("recipe",
                               DeepLinkRoute(pattern: [
                                DeepLinkPattern.or("recipes",
                                                   DeepLinkRoute(pattern: [
                                                    DeepLinkPattern.string("recipes"),
                                                    DeepLinkPattern.string("archive"),
                                                    ])
                                )]
                )
            ),
            DeepLinkPattern.any,
            DeepLinkPattern.string("details"),
            DeepLinkPattern.maybe("info"),
            DeepLinkPattern.param(DeepLinkPatternParameter("menuId", type: .num)),
            DeepLinkPattern.param(DeepLinkPatternParameter("recipeId"))
        ]
        
        XCTAssertEqual(pattern, expectedPattern)
    }
    
    func testParamTypeValidation() {
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.bool.validate("true"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.bool.validate("false"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.bool.validate("True"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.bool.validate("False"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.bool.validate("TRUE"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.bool.validate("FALSE"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.bool.validate("0"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.bool.validate("1"))
        XCTAssertFalse(DeepLinkPatternParameter.ParamType.bool.validate("123"))
        XCTAssertFalse(DeepLinkPatternParameter.ParamType.bool.validate("abc"))

        XCTAssertTrue(DeepLinkPatternParameter.ParamType.num.validate("123"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.num.validate("123"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.num.validate("123.456"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.num.validate("123.456e+07"))
        XCTAssertFalse(DeepLinkPatternParameter.ParamType.num.validate("abc"))
        
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.str.validate("abc"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.str.validate("true"))
        XCTAssertTrue(DeepLinkPatternParameter.ParamType.str.validate("123"))
    }
    
}

extension DeeperTests {
    
    func testThatItDoesNotOpenURLWithWrongScheme() {
        let router = DeepLinkRouter(scheme: "app", rootDeepLinkHandler: FinalHandler())
        router.add(routes: ["recipes"]) { _, _ in .action }
        XCTAssertFalse(router.canOpen(url: URL(string: "http://recipes")!))
    }
    
    private func routeURL<H: DeepLinkHandler>(handler: H) where H.Intent == Intent {
        let router = DeepLinkRouter(scheme: "app", rootDeepLinkHandler: handler)
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
