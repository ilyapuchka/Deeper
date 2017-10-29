//
//  Utils.swift
//  Deeper
//
//  Created by Ilya Puchka on 09/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

// stolen from Sourcery source code ¯\_(ツ)_/¯
extension String {
    
    @discardableResult
    mutating func trimPrefix(_ prefix: String) -> Bool {
        guard hasPrefix(prefix) else { return false }
        self = String(characters.suffix(characters.count - prefix.characters.count))
        return true
    }

    func trimmingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(characters.suffix(characters.count - prefix.characters.count))
    }

    @discardableResult
    mutating func trimSuffix(_ suffix: String) -> Bool {
        guard hasSuffix(suffix) else { return false }
        self = String(characters.prefix(characters.count - suffix.characters.count))
        return true
    }

    func trimmingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(characters.prefix(characters.count - suffix.characters.count))
    }

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
