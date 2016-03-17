//
//  regular.swift
//  Regular_Expression
//
//  Created by 赵翔 on 3/10/16.
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
    
    internal var namedPattern = [String: String]()
    
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
        
         convertString()
         patternIndex = patternString.startIndex
         sourceIndex = sourceString.startIndex
        
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
    
    func rangeOf(start start: Character, end: Character) -> [String] {
        let startAsciiCode = String(start).utf8.first!
        let endAsciiCode = String(end).utf8.first!
        
        var characterSet = [String]()
        
        for i in startAsciiCode...endAsciiCode {
            let value = UnicodeScalar.init(i)
            characterSet.append(String(value))
        }
        
        return characterSet
    }
    
    mutating func parseCharacter() {
        lastCharacter = getNextFromPattern(getCharOption.Consume)!
        
        if lastCharacter == "." {
            for ch in asciiCharacter {
                addValidCharacter(ch)
            }
            lastCharacter = ""
        }
        else if lastCharacter == "\\" {
            lastCharacter = getNextFromPattern(getCharOption.Consume)!
            
            if lastCharacter == "d" {
                let numbers = rangeOf(start: "0", end: "9")
                for number in numbers {
                    addValidCharacter(number)
                }
                lastCharacter = ""
            }
            else if lastCharacter == "w" {
                let lowercases = rangeOf(start: "a", end: "z")
                for lowercase in lowercases {
                    addValidCharacter(lowercase)
                }
                lastCharacter = ""
            }
            else if lastCharacter == "W" {
                let lowercases = rangeOf(start: "A", end: "Z")
                for lowercase in lowercases {
                    addValidCharacter(lowercase)
                }
                lastCharacter = ""
            }
            else if lastCharacter == "s" {
                addValidCharacter("\n")
                addValidCharacter("\t")
                addValidCharacter("\r")
                addValidCharacter(" ")
            }
        }
    }
    
    mutating func parseCharacterClass() {
        getNextFromPattern(getCharOption.Consume)
        
        var nextChar = getNextFromPattern(getCharOption.Consume)
        var exlcude = false
        
        while nextChar != "]" {
            if nextChar == "^" {
                exlcude = true
                nextChar = getNextFromPattern(getCharOption.NotConsume)
            }
            else if nextChar == "-" {
                let prev = patternString[patternIndex.predecessor().predecessor()]
                let next = patternString[patternIndex]
                
                let rangeOfCharacter = rangeOf(start: prev, end: next)
                
                for c in rangeOfCharacter {
                    addValidCharacter(c)
                }
                
                patternIndex = patternIndex.advancedBy(1)
            }
            else {
                addValidCharacter(nextChar!)
            }

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
            restorePoint = sourceIndex
            isFirstMatch = false
        }
        
        if validCharacter.isEmpty {
            // Match with single character
            let nextChar = getNextFromSource(getCharOption.NotConsume)
            if lastCharacter == nextChar {
                sourceIndex = sourceIndex.successor()
            }
            else {
                patternIndex = patternString.startIndex
                sourceIndex = restorePoint.successor()
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
                    validCharacter.removeAll()
                    return
                }
            }
            patternIndex = patternString.startIndex
            sourceIndex = restorePoint.successor()
            isFirstMatch = true
            
            validCharacter.removeAll()
        }
    }
    
    mutating func multiMatch() {
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
        
        while sourceIndex != sourceString.endIndex {
            while patternIndex != patternString.endIndex {
                if sourceIndex == sourceString.endIndex {
                    restorePoint = sourceString.endIndex
                    break
                }
                
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
                    let value = patternString[patternIndex.advancedBy(1)]
                    if value == "?" {
                        parseSubPattern()
                    }
                    else {
                        parseStringclass()
                    }
                }
                else if nextChar == "+" {
                    singleMultiMatch()
                }
                else {
                    parseCharacter()
                }
                nextChar = getNextFromPattern(getCharOption.NotConsume)
            }
            
            let range = Range.init(start: restorePoint, end: sourceIndex)
            let value = sourceString[range]
            
            if value != "" {
                matchedString.append(value)
            }
            
            patternIndex = patternString.startIndex
            if sourceIndex != sourceString.endIndex {
                sourceIndex = sourceIndex.successor()
            }
        }
    }
    
    mutating func convertString() {
        var index = patternString.startIndex
        var insertPoint: [String.Index] = [index]
        insertPoint.removeAll()
        
        var addSymbol = false
        
        var nextChar = patternString[index]
        
        while index != patternString.endIndex {
            if nextChar == "(" {
                index = index.successor()
                nextChar = patternString[index]
                
                if nextChar == "?" {
                    addSymbol = false
                }
                else {
                    addSymbol = true
                }
                
                var brackets = 1
                
                while nextChar != ")" && brackets != 0 {
                    nextChar = patternString[index]

                    if nextChar == "(" {
                        brackets += 1
                        index = index.successor()
                    }
                    else if nextChar == ")" {
                        brackets -= 1
                        if brackets != 0 {
                            index = index.successor()
                            nextChar = patternString[index]
                        }
                    }
                    else {
                        index = index.successor()
                    }
                }
                
                if addSymbol == true {
                    if index.successor() == patternString.endIndex {
                        insertPoint.append(patternString.endIndex)
                        index = index.successor()
                        break
                    }
                    let v = patternString[index.successor()]
                    if v != "*" && v != "+" && v != "?" {
                        insertPoint.append(index.successor())
                    }
                }
                
                if index.successor() != patternString.endIndex {
                    index = index.successor()
                    nextChar = patternString[index]
                }
                else {
                    return
                }
            }
            else if nextChar == "[" {
                while nextChar != "]" {
                    index = index.successor()
                    nextChar = patternString[index]
                }
                
                if index.successor() == patternString.endIndex {
                    insertPoint.append(patternString.endIndex)
                    index = index.successor()
                    break
                }
                
                let v = patternString[index.successor()]
                
                if v != "*" && v != "+" && v != "?" {
                    insertPoint.append(index.successor())
                }
                
                index = index.successor()
                nextChar = patternString[index]
            }
            else if nextChar == "*" || nextChar == "+" || nextChar == "?" {
                if index.successor() == patternString.endIndex {
                    break
                }
                else {
                    index = index.successor()
                    nextChar = patternString[index]
                }
            }
            else {
                if index.successor() == patternString.endIndex {
                    insertPoint.append(patternString.endIndex)
                    index = index.successor()
                    break
                }
                
                let v = patternString[index.successor()]
                
                if v != "*" && v != "+" && v != "?" {
                    insertPoint.append(index.successor())
                }
                
                index = index.successor()
                nextChar = patternString[index]
            }
        }
        
        for var i = insertPoint.count - 1; i >= 0; i-- {
            patternString.insert("#", atIndex: insertPoint[i])
        }
    }
    
    func isValid(str: String) -> Bool {
        return str != "(" && str != ")" && str != "|"
            && str != "[" && str != "]" &&  str != "*"
            && str != "?" && str != "#"
    }
}
