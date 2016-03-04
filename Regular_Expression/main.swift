//
//  main.swift
//  Regular_Expression
//
//  Created by 赵翔 on 3/1/16.
//  Copyright © 2016 赵翔. All rights reserved.
//

import Foundation

enum getCharOption {
    case Consume
    case NotConsume
}

struct Pattern {
    internal var patternString: String
    internal var sourceString: String
    
    internal var patternIndex: String.Index
    internal var sourceIndex: String.Index
    
    internal var matchedString: [String]
    internal var lastCharacter: String
    
    internal var validCharacter: Set<String>
    
    internal var asciiCharacter: Set<String>
    
    internal var restorePoint: String.Index
    
    internal var isFirstMatch = true
    
    init(pattern: String, source: String) {
        patternString = pattern
        sourceString = source
        
        patternIndex = patternString.startIndex
        sourceIndex = sourceString.startIndex
        
        matchedString = [String]()
        lastCharacter = ""
        validCharacter = Set<String>()
        asciiCharacter = Set<String>()
        
        restorePoint = sourceIndex
        
        for index in 0..<128 {
            let code = UnicodeScalar.init(index)
            asciiCharacter.insert(code.escape(asASCII: true))
        }
        
        // convertString()
        // patternIndex = patternString.startIndex
        // sourceIndex = sourceString.startIndex
        
    }
    
    internal func isValidCharacter(ch: String) -> Bool {
        return validCharacter.contains(ch)
    }
    
    mutating func addValidCharacter(ch: String) {
        if validCharacter.contains(ch) {
            return
        }
        else {
            validCharacter.insert(ch)
        }
    }
    
    mutating func getNextFromPattern(option: getCharOption) -> String? {
        if patternIndex == patternString.endIndex {
            return nil
        }
        else {
            let value = patternString[patternIndex]
            if option == getCharOption.Consume {
                patternIndex = patternIndex.successor()
            }
            return String(value)
        }
    }
    
    mutating func getNextFromSource(option: getCharOption) -> String? {
        if sourceIndex == sourceString.endIndex {
            return nil
        }
        else {
            let value = sourceString[sourceIndex]
            if option == getCharOption.Consume {
                sourceIndex = sourceIndex.successor()
            }
            return String(value)
        }
    }
    
    mutating func parseCharacter() {
        lastCharacter = getNextFromPattern(getCharOption.Consume)!
    }
    
    mutating func parseCharacterClass() {
        getNextFromPattern(getCharOption.Consume)
        
        var nextChar = getNextFromPattern(getCharOption.Consume)
        var exlcude = false
        
        while nextChar != "]" {
            if nextChar == "^" {
                exlcude = true
                nextChar = getNextFromPattern(getCharOption.Consume)
            }
            
            addValidCharacter(nextChar!)
            nextChar = getNextFromPattern(getCharOption.Consume)
        }
        
        if exlcude == true {
            validCharacter.exclusiveOrInPlace(asciiCharacter)
        }
    }
    
    mutating func parseStringclass() {
        getNextFromPattern(getCharOption.Consume)
        
        var nextChar = getNextFromPattern(getCharOption.Consume)
        
        var stringClass = ""
        
        while nextChar != ")" {
            while nextChar != "|" && nextChar != ")" {
                stringClass += nextChar!
                nextChar = getNextFromPattern(getCharOption.Consume)
            }
            
            if nextChar == "|" {
                addValidCharacter(stringClass)
                nextChar = getNextFromPattern(getCharOption.Consume)
                stringClass = ""
            }
            else if nextChar == ")" {
                addValidCharacter(stringClass)
                nextChar = getNextFromPattern(getCharOption.NotConsume)
                return
            }
        }
    }
    
    mutating func singleMatch() {
        getNextFromPattern(getCharOption.Consume)
        
        if isFirstMatch == true {
            restorePoint = sourceIndex.successor()
            isFirstMatch = false
        }
        
        if validCharacter.isEmpty {
            // Match with single character
            let nextChar = getNextFromSource(getCharOption.NotConsume)
            
            if lastCharacter == nextChar! {
                sourceIndex = sourceIndex.successor()
            }
            else {
                patternIndex = patternString.startIndex
                sourceIndex = restorePoint
                isFirstMatch = true
            }
            
            lastCharacter = ""
        }
        else {
            // match with single string
            let range = Range.init(start: sourceIndex, end: sourceString.endIndex)
            let rangeString = sourceString[range]
            
            for str in validCharacter {
                if rangeString.hasPrefix(str) {
                    sourceIndex = sourceIndex.advancedBy(str.characters.count)
                    patternIndex = patternIndex.successor()
                    validCharacter.removeAll()
                    return
                }
            }
            patternIndex = patternString.startIndex
            sourceIndex = restorePoint
            isFirstMatch = true
            validCharacter.removeAll()
        }
    }
    
    mutating func multiMatch() {
        if isFirstMatch == true {
            restorePoint = sourceIndex.successor()
            isFirstMatch = false
        }
        
        if validCharacter.isEmpty {
            // Match with single character
            var nextChar = getNextFromSource(getCharOption.NotConsume)
            
            while nextChar == lastCharacter {
                sourceIndex = sourceIndex.successor()
                nextChar = getNextFromSource(getCharOption.NotConsume)
            }
            
            lastCharacter = ""
        }
        else {
            // match with single string
            var range = Range.init(start: sourceIndex, end: sourceString.endIndex)
            var rangeString = sourceString[range]
            
            for str in validCharacter {
                while rangeString.hasPrefix(str) {
                    sourceIndex = sourceIndex.advancedBy(str.characters.count)
                    range = Range.init(start: sourceIndex, end: sourceString.endIndex)
                    rangeString = sourceString[range]
                }
            }
            validCharacter.removeAll()
        }
        
        getNextFromPattern(getCharOption.Consume)
    }
    
    mutating func optionalMatch() {
        getNextFromPattern(getCharOption.Consume)
        
        if isFirstMatch == true {
            restorePoint = sourceIndex.successor()
            isFirstMatch = false
        }
        
        if validCharacter.isEmpty {
            // Match with single character
            let nextChar = getNextFromSource(getCharOption.NotConsume)
            
            if nextChar == lastCharacter {
                sourceIndex = sourceIndex.successor()
            }
            
            lastCharacter = ""
        }
        else {
            // match with single string
            let range = Range.init(start: sourceIndex, end: sourceString.endIndex)
            let rangeString = sourceString[range]
            
            for str in validCharacter {
                if rangeString.hasPrefix(str) {
                    sourceIndex = sourceIndex.advancedBy(str.characters.count)
                    validCharacter.removeAll()
                    return
                }
            }
            validCharacter.removeAll()
        }
    }
    
    mutating func match() {
        var nextChar = getNextFromPattern(getCharOption.NotConsume)
        
        while patternIndex != patternString.endIndex {
            if nextChar == "#" {
                singleMatch()
            }
            else if nextChar == "*" {
                multiMatch()
            }
            else if nextChar == "?" {
                optionalMatch()
            }
            else if nextChar == "[" {
                parseCharacterClass()
            }
            else if nextChar == "(" {
                parseStringclass()
            }
            else {
                parseCharacter()
            }
            nextChar = getNextFromPattern(getCharOption.NotConsume)
        }
        
        let range = Range.init(start: restorePoint.predecessor(), end: sourceIndex)
        let value = sourceString[range]
        
        matchedString.append(value)
    }
    
    mutating func convertString() {
        var index: String.Index = patternString.startIndex
        var r = patternString[index]
        var insertPoints: [String.Index] = [index]
        insertPoints.popLast()
        
        while index != patternString.endIndex {
            if index == patternString.endIndex {
                let preValue = String(patternString[patternIndex.predecessor()])
                if preValue != "?" || preValue != "*" {
                    insertPoints.append(index)
                }
                break
            }
            
            r = patternString[index]
            
            if r == "(" {
                if index != patternString.startIndex &&
                    isValid(String(patternString[index.predecessor()])) {
                        insertPoints.append(index)
                }
                
                if index != patternString.startIndex && patternString[index.predecessor()] == ")" {
                    insertPoints.append(index)
                }
                
                while r != ")" {
                    if index == patternString.endIndex {
                        break
                    }
                    
                    index = index.successor()
                    r = patternString[index]
                }
            }
            else if isValid(String(r)) {
                if index != patternString.startIndex &&
                    isValid(String(patternString[index.predecessor()])) {
                        insertPoints.append(index)
                }
                
                if index != patternString.startIndex &&  patternString[index.predecessor()] == ")" {
                    insertPoints.append(index)
                }
                
                index = index.successor()
            }
            else if r == "*" || r == "?" {
                index = index.successor()
            }
            else if r == ")" {
                index = index.successor()
            }
        }
        
        while let i = insertPoints.popLast() {
            patternString.insert("#", atIndex: i)
        }
        patternString.insert("#", atIndex: patternString.endIndex)
        
        patternIndex = patternString.startIndex
    }
    
    func isValid(str: String) -> Bool {
        return str != "(" && str != ")" && str != "|"
            && str != "[" && str != "]" &&  str != "*"
            && str != "?" && str != "#"
    }
}


var r = Pattern(pattern: "a#b#c#(def)*", source: "abcdeafdef")
r.match()

for i in r.matchedString {
    print(i)
}








