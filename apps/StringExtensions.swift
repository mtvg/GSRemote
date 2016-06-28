//
//  StringExtensions.swift
//  GSRemote
//
//  Created by Niophys on 6/27/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

extension String {
    func split(len: Int) -> [String] {
        var currentIndex = 0
        var array = [String]()
        let length = self.characters.count
        while currentIndex < length {
            let startIndex = self.startIndex.advancedBy(currentIndex)
            let endIndex = startIndex.advancedBy(len, limit: self.endIndex)
            let substr = self.substringWithRange(startIndex..<endIndex)
            array.append(substr)
            currentIndex += len
        }
        return array
    }
}