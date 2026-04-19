//
//  Item.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 6/24/25.
//

import Foundation
import SwiftData

@Model
final class Item {
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
}
