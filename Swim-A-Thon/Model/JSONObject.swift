//
//  JSONObject.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/22/26.
//

import Foundation

protocol JSONObject: Encodable {
    func toJSON(prettyPrint: Bool) -> String?
}

extension JSONObject {
    func toJSON(prettyPrint: Bool = true) -> String? {
        let encoder = JSONEncoder()
        
        if prettyPrint {
            encoder.outputFormatting = .prettyPrinted
        }
        
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Encoding error: \(error)")
            return nil
        }
    }
}
