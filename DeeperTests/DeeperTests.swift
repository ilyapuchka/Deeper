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

func AssertMatches(_ route: DeepLinkRouteConvertible, _ url: String, params: [DeepLinkPatternParameter: String]? = nil, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    let result = DeepLinkPatternMatcher(route: route, url: URL(string: url)!).match()
    XCTAssertTrue(result.0, message, file: file, line: line)
    if let expectedParams = params {
        XCTAssertEqual(result.1, expectedParams, message, file: file, line: line)
    }
}

func AssertNotMatch(_ route: DeepLinkRouteConvertible, _ url: String, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    let result = DeepLinkPatternMatcher(route: route, url: URL(string: url)!).match()
    XCTAssertFalse(result.0, message, file: file, line: line)
    XCTAssertEqual(result.1, [:])
}

class DeeperTests: XCTestCase {
    
    func testThatPatternMatchesString() {
        var route: DeepLinkRoute
        
        route = "recipes"
        AssertMatches(route, "http://recipes")
        AssertNotMatch(route, "http://recipe")
        AssertNotMatch(route, "http://recipe/archive")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipes/archive"
        AssertMatches(route, "http://recipes/archive")
        AssertNotMatch(route, "http://recipes/archives")
        AssertNotMatch(route, "http://recipes")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)
    }

    func testThatPatternMatchesParameter() {
        var route: DeepLinkRoute

        // have to use empty string as there is no convertion between param and pattern,
        // though this pattern is not likely to be used in real scenarios
        route = "" / .recipeId
        AssertMatches(route, "http://123", params: [.recipeId: "123"])
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = .recipes / .menuId / .recipeId
        AssertMatches(route, "http://recipes/123/456", params: [.menuId: "123", .recipeId: "456"])
        AssertNotMatch(route, "http://recipes/abc/456")
        AssertNotMatch(route, "http://recipe/123")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = .recipes / ":num()" / .recipeId
        AssertMatches(route, "http://recipes/123/456", params: [.recipeId: "456"])
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = .recipeId / .recipes
        AssertMatches(route, "http://123/recipes", params: [.recipeId: "123"])
        AssertNotMatch(route, "http://123/recipe")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)
    }
    
    func testThatPatternMatchesCondition() {
        var route: DeepLinkRoute

        route = "recipe" | .recipes
        AssertMatches(route, "http://recipe")
        AssertMatches(route, "http://recipes")
        AssertNotMatch(route, "http://recipes/archive")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = ("recipe" | "recipes") / "archive"
        AssertMatches(route, "http://recipe/archive")
        AssertMatches(route, "http://recipes/archive")
        AssertNotMatch(route, "http://recipes/archives")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = ("recipe" | "recipes" | "recipes" / "archive") / .recipeId
        AssertMatches(route, "http://recipe/123", params: [.recipeId: "123"])
        AssertMatches(route, "http://recipes/archive/123", params: [.recipeId: "123"])
        AssertMatches(route, "http://recipes/123", params: [.recipeId: "123"])
        AssertNotMatch(route, "http://recipes/archive/id/123")
        AssertNotMatch(route, "http://recipes/all/123")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = (("recipe" / .recipeId) | ("recipes" / .recipeId / "details"))
        AssertMatches(route, "http://recipe/123", params: [.recipeId: "123"])
        AssertMatches(route, "http://recipes/123/details", params: [.recipeId: "123"])
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)
    }
    
    func testThatPatternMatchesMaybe() {
        var route: DeepLinkRoute
        
        route = "recipe" / "(details)" / "archive"
        AssertMatches(route, "http://recipe/details/archive")
        AssertMatches(route, "http://recipe/archive")
        AssertNotMatch(route, "http://recipe")
        AssertNotMatch(route, "http://recipe/archive/data")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" /? ("details" / .recipeId)
        AssertMatches(route, "http://recipe/details/123", params: [.recipeId: "123"])
        AssertMatches(route, "http://recipe/details")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" /? ("details" | "detail") / .recipeId
        AssertMatches(route, "http://recipe/details/123", params: [.recipeId: "123"])
        AssertMatches(route, "http://recipe/detail/123", params: [.recipeId: "123"])
        AssertMatches(route, "http://recipe/123", params: [.recipeId: "123"])
        AssertNotMatch(route, "http://recipe/archive/123")
        AssertNotMatch(route, "http://recipe/details/detail/123")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" /? "details" /? "detail" / .recipeId
        AssertMatches(route, "http://recipe/details/123", params: [.recipeId: "123"])
        AssertMatches(route, "http://recipe/detail/123", params: [.recipeId: "123"])
        AssertMatches(route, "http://recipe/details/detail/123", params: [.recipeId: "123"])
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)
    }

    func testThatPatternMatchesAny() {
        var route: DeepLinkRoute
        
        route = "recipe" / .any
        AssertMatches(route, "http://recipe/123")
        AssertNotMatch(route, "http://recipe")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = .any / "recipe"
        AssertMatches(route, "http://some/recipe")
        AssertNotMatch(route, "http://recipe")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = .recipeId / .any / "recipe"
        AssertMatches(route, "http://123/recipe/recipe", params: [.recipeId: "123"])
        AssertNotMatch(route, "http://123/recipe")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" / .any / "details"
        AssertMatches(route, "http://recipe/archive/details")
        AssertMatches(route, "http://recipe/archive/123/details")
        AssertNotMatch(route, "http://recipe/details")
        AssertNotMatch(route, "http://recipe/archive/details/123")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" / .any / "details" / .any
        AssertMatches(route, "http://recipe/archive/details/123")
        AssertNotMatch(route, "http://recipe/archive/details")
        AssertNotMatch(route, "http://recipe/archive")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" / .any / ("details" / "recipe" | "view") / .any
        AssertMatches(route, "http://recipe/archive/details/recipe/123")
        AssertMatches(route, "http://recipe/archive/view/123")
        AssertNotMatch(route, "http://recipe/archive/details/123")
        AssertNotMatch(route, "http://recipe/archive/overview/123")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" / .any / "details" / .recipeId
        AssertMatches(route, "http://recipe/archive/details/123", params: [.recipeId: "123"])
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" / .any / .recipeId
        AssertNotMatch(route, "http://recipe/archive/details/123", "any can be used only in the end or between two string patterns")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)

        route = "recipe" / .any / .any
        AssertNotMatch(route, "http://recipe/archive/details/123", "can't have two any next to each other")
        XCTAssertEqual(parsePattern(route.rawValue), route.pattern)
    }
    
    func testThatPatternMatchesQueryParameters() {
        var route: DeepLinkRouteConvertible

        route = "recipe" .? .recipeId & .menuId
        AssertMatches(route, "http://recipe?recipeId=1&menuId=2", params: [.recipeId: "1", .menuId: "2"])
        AssertMatches(route, "http://recipe?menuId=2&recipeId=1", params: [.recipeId: "1", .menuId: "2"])
        AssertNotMatch(route, "http://recipe?recipeId=1&menuId=abc")
        AssertNotMatch(route, "http://recipe?recipeId=1")
        AssertNotMatch(route, "http://recipe?menuId=2")
        AssertNotMatch(route, "http://recipe?recipeId=1&orderId=2")
        XCTAssertEqual(parsePattern(route.route.rawValue), route.route.pattern)

        route = "recipe" .?? .recipeId & .menuId
        AssertMatches(route, "http://recipe?recipeId=1&menuId=2", params: [.recipeId: "1", .menuId: "2"])
        AssertMatches(route, "http://recipe?menuId=2", params: [.menuId: "2"])
        XCTAssertEqual(parsePattern(route.route.rawValue), route.route.pattern)

        route = "recipe" .? .recipeId &? .menuId
        AssertMatches(route, "http://recipe?recipeId=1&menuId=2", params: [.recipeId: "1", .menuId: "2"])
        AssertMatches(route, "http://recipe?recipeId=1", params: [.recipeId: "1"])
        XCTAssertEqual(parsePattern(route.route.rawValue), route.route.pattern)

        route = "recipe" .?? .recipeId &? .menuId
        AssertMatches(route, "http://recipe")
        XCTAssertEqual(parsePattern(route.route.rawValue), route.route.pattern)

        route = "recipe" .? (.recipeId | .menuId)
        AssertMatches(route, "http://recipe?recipeId=1", params: [.recipeId: "1"])
        AssertMatches(route, "http://recipe?menuId=2", params: [.menuId: "2"])
        AssertNotMatch(route, "http://recipe")
        XCTAssertEqual(parsePattern(route.route.rawValue), route.route.pattern)
    }
    
    func testStringToPatternConversion() {
        let stringFormat = "(recipe|recipes|recipes/archive)/*/details/(info)/:num(menuId)/:recipeId?:recipeId&(:num(menuId))&(:utm|:tmp)"
        let pattern = stringFormat.pattern
        let query = stringFormat.query
        let expectedPattern: [DeepLinkPathPattern] = [
            DeepLinkPathPattern.or("recipe",
                               DeepLinkRoute(pattern: [
                                DeepLinkPathPattern.or("recipes",
                                                   DeepLinkRoute(pattern: [
                                                    DeepLinkPathPattern.string("recipes"),
                                                    DeepLinkPathPattern.string("archive"),
                                                    ])
                                )]
                )
            ),
            DeepLinkPathPattern.any,
            DeepLinkPathPattern.string("details"),
            DeepLinkPathPattern.maybe("info"),
            DeepLinkPathPattern.param(DeepLinkPatternParameter("menuId", type: .num)),
            DeepLinkPathPattern.param(DeepLinkPatternParameter("recipeId"))
        ]
        let expectedQuery: [DeepLinkQueryPattern] = [
            DeepLinkQueryPattern.param(DeepLinkPatternParameter("recipeId")),
            DeepLinkQueryPattern.maybe(DeepLinkPatternParameter("menuId", type: .num)),
            DeepLinkQueryPattern.or(DeepLinkPatternParameter("utm"), DeepLinkPatternParameter("tmp"))
        ]
        
        XCTAssertEqual(pattern, expectedPattern)
        XCTAssertEqual(query, expectedQuery)
        let parsed = parsePattern(stringFormat)
        XCTAssertEqual(parsed, expectedPattern)
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
