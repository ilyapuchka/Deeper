//
//  DeeperFuncTests.swift
//  DeeperFuncTests
//
//  Created by Ilya Puchka on 26/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import XCTest
@testable import DeeperFunc

class DeeperFuncTests: XCTestCase {
    
    var router: Router<Intent>!
    
    func makeRouter() -> Router<Intent> {
        class Handler: AnyDeepLinkHandler<Intent> { }
        return Router(scheme: "app", rootDeepLinkHandler: Handler())
    }
    
    override func setUp() {
        router = makeRouter()
    }
    
    func AssertMatch(_ intent: Intent, _ url: String, file: StaticString = #file, line: UInt = #line) {
        let url = URL(string: url)!
        let matched = router.openURL(url)
        XCTAssertNotNil(matched, file: file, line: line)
        XCTAssertEqual(matched, intent, file: file, line: line)
    }
    
    func AssertNotMatch(_ url: String, file: StaticString = #file, line: UInt = #line) {
        let url = URL(string: url)!
        let matched = router.openURL(url)
        XCTAssertNil(matched, file: file, line: line)
    }

    func testSimpleRoute() {
        router.add(Intent.empty, route: "recipes" /> "info")
        
        AssertMatch(Intent.empty, "app://recipes/info")
        AssertNotMatch("app://recipes/data")
        AssertNotMatch("app://recipes")
        AssertNotMatch("app://recipes/info/123")
    }
    
    func testLongPattern() {
        router.add(Intent.empty, route: "recipes" /> "info" /> "a" /> "b" /> "c" /> "d" /> "e" /> "f")
        
        AssertMatch(Intent.empty, "app://recipes/info/a/b/c/d/e/f")
    }
    
    func testRouteWithPathParamAndQuery() {
        router.add(Intent.pathAndQueryParams, route: "recipes" /> int >/> string .? int("recipeId") & string("t"))
        
        AssertMatch(Intent.pathAndQueryParams(123, "abc", 456, "A"), "app://recipes/123/abc?recipeId=456&t=A")
        AssertMatch(Intent.pathAndQueryParams(123, "abc", 456, "A"), "app://recipes/123/abc?t=A&recipeId=456")
        AssertNotMatch("app://recipes/abc/abc?recipeId=456&t=A")
        AssertNotMatch("app://recipes/abc?recipeId=456&t=A")
        AssertNotMatch("app://recipes/123/abc?recipeId=abc&t=A")
        AssertNotMatch("app://recipes/123/abc?t=A")
        AssertNotMatch("app://recipes/123/abc?recipeId=abc")
    }
    
    func testPathWithParams() {
        router.add(Intent.singleParam, route: "subscription" /> int)
        
        AssertMatch(Intent.singleParam(123), "app://subscription/123")
        AssertNotMatch("app://subscription/abc")
        AssertNotMatch("app://subscription/true")
        AssertNotMatch("app://subscription/abc/123")

        router = makeRouter()
        router.add(Intent.twoParams, route: "subscription" /> int >/> "menu" >/> string)
        
        AssertMatch(Intent.twoParams(123, "abc"), "app://subscription/123/menu/abc")
        AssertNotMatch("app://subscription/abc/menu/123")
    }
    
    func testAnyPatternInMiddleRoute() {
        router.add(Intent.anyMiddle, route: "recipes" /> "id" /> any /> "data" /> "abc")
        
        AssertMatch(Intent.anyMiddle, "app://recipes/id/123/foo/data/abc")
        AssertNotMatch("app://recipes/id/data/abc")

        router = makeRouter()
        router.add(Intent.anyMiddleParam, route: "recipes" /> "id" /> any /> int >/> "data" >/> "abc")
        
        AssertMatch(Intent.anyMiddleParam(123), "app://recipes/id/foo/123/data/abc")
        AssertNotMatch("app://recipes/id/foo/123/456/data/abc")
        AssertNotMatch("app://recipes/id/123/data/abc")

        router = makeRouter()
        router.add(Intent.anyMiddleParam, route: "recipes" /> "id" /> any /> "data" /> int >/> "abc")
        
        AssertMatch(Intent.anyMiddleParam(456), "app://recipes/id/123/data/456/abc")
        AssertNotMatch("app://recipes/id/foo/data/abc")

        router = makeRouter()
        router.add(Intent.anyMiddleParam, route: "recipes" /> "id" /> int >/> any >/> "data" >/> "abc")
        
        AssertMatch(Intent.anyMiddleParam(123), "app://recipes/id/123/abc/foo/data/abc")
        AssertNotMatch("app://recipes/id/foo/data/abc")

        router = makeRouter()
        router.add(Intent.anyMiddleParam, route: "recipes" /> int >/> "id" >/> any >/> "data" >/> "abc")
        
        AssertMatch(Intent.anyMiddleParam(123), "app://recipes/123/id/foo/data/abc")
        AssertNotMatch("app://recipes/id/abc/foo/data/abc")
        
        router = makeRouter()
        router.add(Intent.anyMiddleParams, route: "recipes" /> "id" /> int >/> any >/> "data" >/> int >/> "abc")
        
        AssertMatch(Intent.anyMiddleParams(123, 456), "app://recipes/id/123/foo/data/456/abc")
        
        router = makeRouter()
        router.add(Intent.anyMiddleParams, route: "recipes" /> "id" /> int >/> any >/> "data" >/> any >/> int >/> "abc")
        AssertMatch(Intent.anyMiddleParams(123, 456), "app://recipes/id/123/foo/data/bar/456/abc")

        router = makeRouter()
        router.add(Intent.anyMiddleParams, route: "recipes" /> int >/> "id" >/> any >/> int >/> "data" >/> "abc")

        AssertMatch(Intent.anyMiddleParams(123, 456), "app://recipes/123/id/foo/456/data/abc")
        
        router = makeRouter()
        router.add(Intent.anyMiddleParams, route: "recipes" /> "id" /> int >/> any >/> int >/> "data" >/> "abc")
        
        AssertMatch(Intent.anyMiddleParams(123, 456), "app://recipes/id/123/foo/456/data/abc")
    }

    func testAnyPatternAtStart() {
        router.add(Intent.anyStart, route: any /> "data" /> "abc")
        
        AssertMatch(Intent.anyStart, "app://foo/123/data/abc")
        AssertMatch(Intent.anyStart, "app://data/data/abc")
        AssertNotMatch("app://123/data/data/abc")

        router = makeRouter()
        router.add(Intent.anyStartParam, route: any /> int >/> "data" >/> "abc")
        AssertMatch(Intent.anyStartParam(123), "app://foo/123/data/abc")

        router = makeRouter()
        router.add(Intent.anyStartParam, route: any /> "data" /> int >/> "abc")
        AssertMatch(Intent.anyStartParam(123), "app://foo/data/123/abc")
    }

    func testAnyPatternAtEndRoute() {
        router.add(Intent.anyEnd, route: "data" /> any)

        AssertMatch(Intent.anyEnd, "app://data/abc/123/456")
        AssertNotMatch("app://data")

        router = makeRouter()
        router.add(Intent.anyEnd, route: "data" /> "abc" /> any)
        
        AssertMatch(Intent.anyEnd, "app://data/abc/123/456")
        AssertMatch(Intent.anyEnd, "app://data/abc/data/abc")
        AssertNotMatch("app://data/abc")

        router = makeRouter()
        router.add(Intent.anyEndParam, route: "data" /> "abc" /> int >/> any)
        AssertMatch(Intent.anyEndParam(123), "app://data/abc/123/456/abc")

        router = makeRouter()
        router.add(Intent.anyEndParam, route: "data" /> int >/> "abc" >/> any)
        AssertMatch(Intent.anyEndParam(123), "app://data/123/abc/456/abc")
        
        router = makeRouter()
        router.add(Intent.anyEndParam, route: "data" /> "abc" /> any .? int("id"))
        AssertMatch(Intent.anyEndParam(1), "app://data/abc/123/foo?id=1")
    }
    
    func testConditionInPath() {
        router.add(Intent.orPattern, route: "recipes" /> ("data" | "info") )

        AssertMatch(Intent.orPattern, "app://recipes/data")
        AssertMatch(Intent.orPattern, "app://recipes/info")
        AssertNotMatch("app://recipes/foo")
        
        router = makeRouter()
        router.add(Intent.eitherIntOrString, route: "recipes" /> ( int >/> "info" | "data" /> string ) )
        
        AssertMatch(Intent.eitherIntOrString(.right("abc")), "app://recipes/data/abc")
        AssertMatch(Intent.eitherIntOrString(.left(123)), "app://recipes/123/info")
    }
    
    func testConditionInQuery() {
        router.add(Intent.eitherIntOrString, route: "recipes" .? ( int("info") | string("data") ) )
        
        AssertMatch(Intent.eitherIntOrString(.right("abc")), "app://recipes?data=abc")
        AssertMatch(Intent.eitherIntOrString(.left(123)), "app://recipes?info=123")
        
        router = makeRouter()
        router.add(Intent.eitherIntOrString, route: "recipes" .? ( "info" .? int("recipeId") | "data" .? string("id") ) )
        
        AssertMatch(Intent.eitherIntOrString(.right("abc")), "app://recipes/data?id=abc")
        AssertMatch(Intent.eitherIntOrString(.left(123)), "app://recipes/info?recipeId=123")
    }
    
    func testMaybePath() {
        router.add(Intent.empty, route: "recipes" /? "data" /> "info")
        
        AssertMatch(Intent.empty, "app://recipes/data/info")
        AssertMatch(Intent.empty, "app://recipes/info")
        
        AssertNotMatch("app://recipes/foo/info")
        AssertNotMatch("app://recipes/data/abc/info")
        
        router = makeRouter()
        router.add(Intent.optionalParam, route: "recipes" /? int >/> "info")

        AssertMatch(Intent.optionalParam(123), "app://recipes/123/info")
        AssertMatch(Intent.optionalParam(nil), "app://recipes/info")
        
        AssertNotMatch("app://recipes/foo/info")
        AssertNotMatch("app://recipes/123/abc/info")
    }
    
    func testMaybeQuery() {
        router.add(Intent.optionalParam, route: "recipes" .?? int("recipeId"))
        
        AssertMatch(Intent.optionalParam(123), "app://recipes?recipeId=123")
        AssertMatch(Intent.optionalParam(nil), "app://recipes")

        router = makeRouter()
        router.add(Intent.optionalSecondParam, route: "recipes" .? int("recipeId") &? string("locale"))
        
        AssertMatch(Intent.optionalSecondParam(123, "en"), "app://recipes?recipeId=123&locale=en")
        AssertMatch(Intent.optionalSecondParam(123, nil), "app://recipes?recipeId=123")
    }
    
    func testTemplates() {
        let route = "recipes" /> (("info" | "archive") | string) >/> "data"
        XCTAssertEqual(route.template, "recipes/((info|archive)|:string)/data")

        let paramRoute = "recipes" /> int /? "data"  >/> string
        XCTAssertEqual(paramRoute.template, "recipes/:int/(data)/:string")

        let queryRoute = "recipes" /> int >/> "data" >/> string .? int("recipeId") & string("s") & bool("b")
        XCTAssertEqual(queryRoute.template, "recipes/:int/data/:string?recipeId=:int&s=:string&b=:bool")

        let complexRoute = "recipes" .? int("recipeId") &? string("s") & (bool("b") | int("i"))
        XCTAssertEqual(complexRoute.template, "recipes?recipeId=:int&(s=:string)&(b=:bool|i=:int)")
        
        let anyRoute = any /> "recipes" /> any /> int >/> "data" >/> string >/> any >/> "info" >/> any
        XCTAssertEqual(anyRoute.template, "*/recipes/*/:int/data/:string/*/info/*")
    }
    
    func AssertFormat(_ format: String, matches url: String, intent: Intent, router: (Router<Intent>, String) -> Router<Intent>, file: StaticString = #file, line: UInt = #line) {
        let url = URL(string: url)!
        
        let route = format.routePattern
        XCTAssertEqual(route?.template, format, "Invalid template", file: file, line: line)
        
        let router = router(makeRouter(), format)

        let printed = router.url(for: intent)
        XCTAssertEqual(printed, url, "Invalid print", file: file, line: line)

        let result = router.openURL(url)
        XCTAssertEqual(result, intent, "Failed to match url", file: file, line: line)
    }

    func testStringFormat() {
        AssertFormat("recipe/info",
                     matches: "app://recipe/info",
                     intent: Intent.empty,
                     router: { $0.add(Intent.empty, format: $1) }
        )
        
        AssertFormat("recipe/:int",
                     matches: "app://recipe/123",
                     intent: Intent.singleParam(123),
                     router: { $0.add(Intent.singleParam, format: $1) }
        )
        
        AssertFormat("recipe/:int/:string",
                     matches: "app://recipe/123/abc",
                     intent: Intent.twoParams(123, "abc"),
                     router: { $0.add(Intent.twoParams, format: $1) }
        )
        
        AssertFormat("recipe/:int/menu/:string?t=:int&locale=:string",
                     matches: "app://recipe/123/menu/abc?t=456&locale=en",
                     intent: Intent.pathAndQueryParams(123, "abc", 456, "en"),
                     router: { $0.add(Intent.pathAndQueryParams, format: $1) }
        )
        
        AssertFormat("recipes/data/(info)?(t=:int)",
                     matches: "app://recipes/data/info?t=1",
                     intent: Intent.singleParam(1),
                     router: { $0.add(Intent.singleParam, format: $1) }
        )
        
        AssertFormat("recipes/*/data/:int",
                     matches: "app://recipes/*/data/1",
                     intent: Intent.singleParam(1),
                     router: { $0.add(Intent.singleParam, format: $1) }
                     )
    }
}
