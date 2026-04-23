//
//  Team.swift
//  APIExamples
//
//  Created by Brame, Tony on 4/22/26.
//


import Foundation
import SwiftData

class Team: JSONObject {
    
    var id: UUID
    var name: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
    
}
