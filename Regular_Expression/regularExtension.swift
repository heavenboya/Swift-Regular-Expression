//
//  regularExtension.swift
//  Regular_Expression
//
//  Created by 赵翔 on 3/9/16.
//  Copyright © 2016 赵翔. All rights reserved.
//

import Foundation

extension Pattern {
    init(pattern: String, dupPattern: Pattern) {
        self.patternString = pattern
        self.patternIndex = pattern.startIndex
        
        self.sourceString = dupPattern.sourceString
        self.sourceIndex = dupPattern.sourceIndex
        
        self.lastCharacter = dupPattern.lastCharacter
        self.validCharacter = dupPattern.validCharacter
        
        self.matchedString = [String]()
        self.asciiCharacter = dupPattern.asciiCharacter
        
        self.isFirstMatch = true
        self.restorePoint = sourceIndex
    }
    
    mutating func singleMultiMatch() {
        if isFirstMatch == true {
            restorePoint = sourceIndex
            isFirstMatch = false
        }
        
        if validCharacter.isEmpty {
            var nextChar = getNextFromSource(getCharOption.NotConsume)
            
            if lastCharacter != nextChar {
                patternIndex = patternString.startIndex
                sourceIndex = restorePoint.successor()
                isFirstMatch = true
            }
            else {
                sourceIndex = sourceIndex.successor()
                nextChar = getNextFromSource(getCharOption.NotConsume)
            }
            
            while lastCharacter == nextChar {
                sourceIndex = sourceIndex.successor()
                nextChar = getNextFromSource(getCharOption.NotConsume)
            }
            
            patternIndex = patternIndex.successor()
            
            lastCharacter = ""
        }
        else {
            var range = Range.init(start: sourceIndex, end: sourceString.endIndex)
            var rangeString = sourceString[range]
            var suc = false
            
            for str in validCharacter {
                if rangeString.hasPrefix(str) {
                    sourceIndex = sourceIndex.advancedBy(str.characters.count)
                    range = Range.init(start: sourceIndex, end: sourceString.endIndex)
                    rangeString = sourceString[range]
                    suc = true
                }
                else {
                    continue
                }
                
                while rangeString.hasPrefix(str) {
                    sourceIndex = sourceIndex.advancedBy(str.characters.count)
                    range = Range.init(start: sourceIndex, end: sourceString.endIndex)
                    rangeString = sourceString[range]
                }
            }
            
            if suc == false {
                patternIndex = patternString.startIndex
                sourceIndex = restorePoint.successor()
                isFirstMatch = true
            }
            
            patternIndex = patternIndex.successor()
            validCharacter.removeAll()
        }
    }
    
    mutating func parseNamedPattern() {
        patternIndex = patternIndex.advancedBy(3)
        var brackets = 1
        
        var nextChar = getNextFromPattern(getCharOption.Consume)
        var patternName = ""
        var subPatternString = ""
        
        if nextChar == "<" {
            nextChar = getNextFromPattern(getCharOption.Consume)
            while nextChar != ">" {
                patternName += nextChar!
                nextChar = getNextFromPattern(getCharOption.Consume)
            }
            
            nextChar = getNextFromPattern(getCharOption.Consume)
            
            while brackets != 0 {
                if nextChar == ")" {
                    brackets -= 1
                    if brackets != 0 {
                        subPatternString += nextChar!
                        nextChar = getNextFromPattern(getCharOption.Consume)
                    }
                }
                else {
                    if nextChar == "(" {
                        brackets += 1
                    }
                    
                    subPatternString += nextChar!
                    nextChar = getNextFromPattern(getCharOption.Consume)
                }
            }
            
            namedPattern[patternName] = subPatternString
        }
    }
    
    mutating func namedPatternMatch() {
        var subPatternName = ""
        patternIndex = patternIndex.advancedBy(4)
        
        var nextChar = getNextFromPattern(getCharOption.Consume)
        
        while nextChar != ")" {
            subPatternName += nextChar!
            nextChar = getNextFromPattern(getCharOption.Consume)
        }
        
        if let p = namedPattern[subPatternName] {
            var subPattern = Pattern(pattern: p, dupPattern: self)
            print(subPattern.patternString)
            print(subPattern.sourceString[sourceIndex])
            subPattern.match()
//            for str in subPattern.matchedString {
//                self.matchedString.append(str)
//            }
            
            if subPattern.matchedString.isEmpty {
//                group match fails
                patternIndex = patternString.startIndex
                sourceIndex = restorePoint.successor()
                isFirstMatch = true
            }
            else {
//                group match success
                let len = subPattern.matchedString.last!.characters.count
                sourceIndex = sourceIndex.advancedBy(len)
            }
        }
        else {
            print("name \"\(subPatternName)\"")
            return
        }
    }
    
    
    mutating func parseSubPattern() {
        let f2 = patternString[patternIndex.advancedBy(2)]
        let f3 = patternString[patternIndex.advancedBy(3)]
        
        if f2 == "P" {
            if f3 == "<" {
                parseNamedPattern()
            }
            else if f3 == "=" {
                namedPatternMatch()
            }
        }
    }
}






