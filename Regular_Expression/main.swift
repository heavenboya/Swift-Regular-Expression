//
//  main.swift
//  Regular_Expression
//
//  Created by 赵翔 on 3/1/16.
//  Copyright © 2016 赵翔. All rights reserved.
//

import Foundation



var r = Pattern(pattern: "[0-9]+", source: "9999999")
print(r.patternString)

r.match()

print("start: ")
for i in r.matchedString {
    print(i)
}








