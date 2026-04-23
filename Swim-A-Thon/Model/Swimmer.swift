//
//  Swimmer.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 6/24/25.
//

import Foundation
import SwiftData

@Model
//TODO: refactor this to rename the object to something that is descriptive (e.g. "Swimmer"). Hint, you can right client the class name, go to Refactor, and enter the new name - it will update across the code base.
//TODO: make a 'model' folder and put your data-classes there.
final class Swimmer {
    
    var id: UUID
    var name: String
    var laps: Int
    var createdAt: Date

    init(id: UUID = UUID(), name: String, laps: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.laps = laps
        self.createdAt = createdAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, laps, createdAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(laps, forKey: .laps)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
}
