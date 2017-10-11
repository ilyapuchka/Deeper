//
//  DeepLinkPatternConvertible.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

public protocol DeepLinkPatternConvertible: CustomStringConvertible {
    var pattern: [DeepLinkPattern] { get }
}

extension DeepLinkPatternParameter: DeepLinkPatternConvertible {
    
    public var pattern: [DeepLinkPattern] {
        return [.param(self)]
    }
    
}

extension String: DeepLinkPatternConvertible {
    
    public var pattern: [DeepLinkPattern] {
        var component = self
        var wrappedInBrackets = false
        if component.hasPrefix("(") && component.hasSuffix(")") {
            component = String(component.dropFirst().dropLast())
            wrappedInBrackets = true
        }
        
        if component == "*" {
            return [.any]
        } else if component.hasPrefix(":") {
            return [.param(DeepLinkPatternParameter(String(component.dropFirst())))]
        } else {
            let orComponents = component.components(separatedBy: "|", excludingDelimiterBetween: ("(", ")"))
            if orComponents.count > 1 {
                let lhs = orComponents[0].pattern.deepLinkPatternConvertible
                let rhs = orComponents.dropFirst().joined(separator: "|").pattern.deepLinkPatternConvertible
                return [.or(lhs, rhs)]
            } else if wrappedInBrackets {
                return [.maybe(DeepLinkRoute(component))]
            } else {
                let components = component.components(separatedBy: "/", excludingDelimiterBetween: ("(", ")"))
                if components.count > 1 {
                    return components.flatMap({ $0.pattern })
                } else {
                    return [.string(component)]
                }
            }
        }
    }
    
}

extension String {
    
    // stolen from Sourcery source code ¯\_(ツ)_/¯
    func components(separatedBy delimiter: String, excludingDelimiterBetween between: (open: String, close: String)) -> [String] {
        var boundingCharactersCount: Int = 0
        var quotesCount: Int = 0
        var item = ""
        var items = [String]()
        var matchedDelimiter = (alreadyMatched: "", leftToMatch: delimiter)
        
        for char in characters {
            if between.open.characters.contains(char) {
                boundingCharactersCount += 1
            } else if between.close.characters.contains(char) {
                boundingCharactersCount = max(0, boundingCharactersCount - 1)
            }
            if char == "\"" {
                quotesCount += 1
            }
            
            guard boundingCharactersCount == 0 && quotesCount % 2 == 0 else {
                item.append(char)
                continue
            }
            
            if char == matchedDelimiter.leftToMatch.characters.first {
                matchedDelimiter.alreadyMatched.append(char)
                matchedDelimiter.leftToMatch = String(matchedDelimiter.leftToMatch.dropFirst())
                if matchedDelimiter.leftToMatch.isEmpty {
                    items.append(item)
                    item = ""
                    matchedDelimiter = (alreadyMatched: "", leftToMatch: delimiter)
                }
            } else {
                if matchedDelimiter.alreadyMatched.isEmpty {
                    item.append(char)
                } else {
                    item.append(matchedDelimiter.alreadyMatched)
                    matchedDelimiter = (alreadyMatched: "", leftToMatch: delimiter)
                }
            }
        }
        items.append(item)
        return items
    }
}

extension Array where Element == DeepLinkPattern {
    
    var deepLinkPatternConvertible: DeepLinkPatternConvertible {
        if count == 1, case .string(let str)? = first {
            return str
        } else {
            return DeepLinkRoute(pattern: self)
        }
    }
    
}
