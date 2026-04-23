//
//  GoogleDocsLogicForAPI.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/23/26.
//

import Foundation

class GoogleDocsLogicForAPI {
    let numberToLetters: [Int: (String, String)] = [
        1: ("A", "B"),
        2: ("C", "D"),
        3: ("E", "F"),
        4: ("G", "H"),
        5: ("I", "J"),
        6: ("K", "L"),
        7: ("M", "N"),
        8: ("O", "P"),
        9: ("Q", "R"),
        10: ("S", "T"),
        11: ("U", "V"),
        12: ("W", "X")
    ]
    func getColumns(for number: Int, columnNumber: Int) -> String {
        print("Calling getColumns with number: \(number), column: \(columnNumber)")
        guard let letters = numberToLetters[number] else {
            print("Invalid number: \(number). Must be 1-10.")
            return ""
        }
        
        switch columnNumber {
        case 1: return letters.0
        case 2: return letters.1
        default:
            print("Invalid columnNumber: \(columnNumber). Must be 1 or 2.")
            return ""
        }
    }
}
