//
//  DeepLinkPatternMatcher.swift
//  Deeper
//
//  Created by Ilya Puchka on 10/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public class DeepLinkPatternMatcher {
    public typealias Result = (matched: Bool, params: [DeepLinkPatternParameter: String])

    private var pattern: IndexingIterator<[DeepLinkPattern]>
    private let patternCount: Int
    
    private var pathComponents: IndexingIterator<[String]>
    private let pathComponentsCount: Int
    
    private var hasUnmatchedPattern: Bool
    private var hasUnmatchedPathComponent: Bool
    
    init(pattern: [DeepLinkPattern], pathComponents: [String]) {
        self.pattern = pattern.makeIterator()
        let pathComponents = pathComponents.filter({ !$0.isEmpty && $0 != "/" })
        self.pathComponents = pathComponents.makeIterator()
        self.hasUnmatchedPattern = !pattern.isEmpty
        self.hasUnmatchedPathComponent = !pathComponents.isEmpty
        self.patternCount = pattern.count
        self.pathComponentsCount = pathComponents.count
    }
    
    func nextPatternAndPathComponent() -> (pattern: DeepLinkPattern, pathComponent: String)? {
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
    
    func match() -> Result {
        let result = matchPatternWithPathComponents()
        // fail if patterns or path components are left
        if hasUnmatchedPattern == hasUnmatchedPathComponent, hasUnmatchedPattern == false {
            return result
        } else {
            return (false, [:])
        }
    }
    
    private func matchPatternWithPathComponents() -> Result {
        var params = [DeepLinkPatternParameter: String]()
        while let (pattern, pathComponent) = nextPatternAndPathComponent() {
            let result = match(pattern: pattern, pathComponent: pathComponent)
            guard result.matched else { return (false, [:]) }
            params.merge(result.params, uniquingKeysWith: { $1 })
        }
        return (true, params)
    }

    private func match(pattern: DeepLinkPattern, pathComponent: String) -> Result {
        switch pattern {
        case .string(let string):
            return (pathComponent == string, [:])
        case .param(let param):
            return matchParam(param, pathComponent)
        case .or(let lhs, let rhs):
            return matchOr(lhs, rhs, pathComponent)
        case .maybe(let route):
            return matchMaybe(route.pattern, pathComponent)
        case .any:
            return matchAny()
        }
    }
    
    fileprivate func matchParam(_ param: DeepLinkPatternParameter, _ pathComponent: String) -> Result {
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
    }
    
    fileprivate func matchOr(_ lhs: DeepLinkPatternConvertible, _ rhs: DeepLinkPatternConvertible, _ pathComponent: String) -> Result {
        // Tries to recursively match longest pattern first with the rest of path components
        let patterns = [lhs.pattern, rhs.pattern].sorted(by: { $0.count > $1.count })
        
        let pathComponents = [pathComponent] + Array(self.pathComponents)
        for pattern in patterns {
            let _matcher = DeepLinkPatternMatcher(pattern: pattern, pathComponents: pathComponents)
            let result = _matcher.matchPatternWithPathComponents()
            if result.matched {
                // update iterator as we might already matched some paths
                // (this will drop all previosly matched path components)
                self.pathComponents = _matcher.pathComponents
                return result
            }
        }
        return (false, [:])
    }
    
    fileprivate func matchMaybe(_ pattern: [DeepLinkPattern], _ pathComponent: String) -> Result {
        let pathComponents = [pathComponent] + Array(self.pathComponents)
        let _matcher = DeepLinkPatternMatcher(pattern: pattern, pathComponents: pathComponents)
        let result = _matcher.matchPatternWithPathComponents()
        if result.matched {
            self.pathComponents = _matcher.pathComponents
            return result
        }
        self.pathComponents = pathComponents.makeIterator()
        return (true, [:])
    }
    
    fileprivate func matchAny() -> Result {
        // Tries to math any further path with next pattern after `any`
        guard let (nextPattern, nextPathComponent) = nextPatternAndPathComponent() else { return (false, [:]) }
        
        var pathComponents = self.pathComponents
        var component: String! = nextPathComponent
        repeat {
            let result = match(pattern: nextPattern, pathComponent: component)
            if result.matched {
                self.pathComponents = pathComponents
                return result
            } else {
                component = pathComponents.next()
            }
        } while component != nil
        
        // fail as none of the paths matched pattern after `any`
        return (false, [:])
    }
    
}

extension IndexingIterator {
    var isEmpty: Bool {
        var copy = self
        return copy.next() == nil
    }
}

