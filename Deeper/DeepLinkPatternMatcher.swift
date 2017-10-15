//
//  DeepLinkPatternMatcher.swift
//  Deeper
//
//  Created by Ilya Puchka on 10/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public class DeepLinkPatternMatcher {
    public typealias Result = (matched: Bool, params: [DeepLinkPatternParameter: String])

    private(set) var pattern: IndexingIterator<[DeepLinkPattern]>
    let patternCount: Int
    
    private(set) var pathComponents: IndexingIterator<[String]>
    let pathComponentsCount: Int
    
    private(set) var hasUnmatchedPattern: Bool
    private(set) var hasUnmatchedPathComponent: Bool
    
    init(pattern: [DeepLinkPattern], pathComponents: [String]) {
        self.pattern = pattern.makeIterator()
        let pathComponents = pathComponents.filter({ !$0.isEmpty && $0 != "/" })
        self.pathComponents = pathComponents.makeIterator()
        self.hasUnmatchedPattern = !pattern.isEmpty
        self.hasUnmatchedPathComponent = !pathComponents.isEmpty
        self.patternCount = pattern.count
        self.pathComponentsCount = pathComponents.count
    }
    
    func next() -> (pattern: DeepLinkPattern, pathComponent: String)? {
        var hasUnmatchedPattern: Bool { return !pattern.isEmpty }
        self.hasUnmatchedPattern = hasUnmatchedPattern
        
        var hasUnmatchedPathComponent: Bool { return !pathComponents.isEmpty }
        self.hasUnmatchedPathComponent = hasUnmatchedPathComponent
        
        guard let nextPattern = pattern.next() else { return nil }
        
        if case .any = nextPattern {
            // fail if we got any pattern but number of components in path is less then number of patterns
            // foo / .any / bar (count 3) pattern should not match foo/bar (count 2)
            // but it should math foo/biz/bar (count 3)
            guard pathComponentsCount >= patternCount else { return nil }
            
            if hasUnmatchedPathComponent {
                if !hasUnmatchedPattern {
                    // if any is the last pattern - stop iteration as it should match everything what's left in the path
                    self.hasUnmatchedPattern = false
                    self.hasUnmatchedPathComponent = false
                    self.pathComponents = [].makeIterator()
                    return nil
                }
            }
        }
        
        guard let nextPathComponent = pathComponents.next() else { return nil }
        return (nextPattern, nextPathComponent)
    }
    
    func match() -> DeepLinkPatternMatcher.Result {
        let result = _match()
        // fail if patterns or path components are left
        if hasUnmatchedPattern == hasUnmatchedPathComponent, hasUnmatchedPattern == false {
            return result
        } else {
            return (false, [:])
        }
    }
    
    private func _match() -> DeepLinkPatternMatcher.Result {
        var params = [DeepLinkPatternParameter: String]()
        while let (pattern, pathComponent) = next() {
            let result = _match(pattern: pattern, pathComponent: pathComponent)
            guard result.matched else { return (false, [:]) }
            params.merge(result.params, uniquingKeysWith: { $1 })
        }
        return (true, params)
    }

    private func _match(pattern: DeepLinkPattern, pathComponent: String) -> DeepLinkPatternMatcher.Result {
        switch pattern {
        case .string(let string):
            return (pathComponent == string, [:])
        case .param(let param):
            if let type = param.type {
                if type.validate(pathComponent) {
                    if !param.rawValue.isEmpty {
                        return (true, [param: pathComponent])
                    } else {
                        return (true, [:])
                    }
                } else {
                    return (false, [:])
                }
            } else {
                return (true, [param: pathComponent])
            }
        case .or(let lhs, let rhs):
            // Tries to recursively match longest pattern first with the rest of path components
            let patterns = [lhs.pattern, rhs.pattern].sorted(by: { $0.count > $1.count })

            let _pathComponents = [pathComponent] + Array(pathComponents)
            for pattern in patterns {
                let _matcher = DeepLinkPatternMatcher(pattern: pattern, pathComponents: _pathComponents)
                let result = _matcher._match()
                if result.matched {
                    // update iterator as we might already matched some paths
                    // (this will drop all previosly matched path components)
                    pathComponents = _matcher.pathComponents
                    return result
                }
            }
            return (false, [:])
        case .maybe(let route):
            let _pathComponents = [pathComponent] + Array(pathComponents)
            let _matcher = DeepLinkPatternMatcher(pattern: route.pattern, pathComponents: _pathComponents)
            let result = _matcher._match()
            if result.matched {
                pathComponents = _matcher.pathComponents
                return result
            }
            return (true, [:])
        case .any:
            // Tries to math any further path with next pattern after `any`
            guard let (nextPattern, nextPathComponent) = next() else { return (false, [:]) }
            
            var _pathComponents = pathComponents
            var component: String! = nextPathComponent
            repeat {
                let result = _match(pattern: nextPattern, pathComponent: component)
                if result.matched {
                    pathComponents = _pathComponents
                    return result
                } else {
                    component = _pathComponents.next()
                }
            } while component != nil
            
            // fail as none of the paths matched pattern after `any`
            return (false, [:])
        }
    }
}

extension IndexingIterator {
    var isEmpty: Bool {
        var copy = self
        return copy.next() == nil
    }
}

