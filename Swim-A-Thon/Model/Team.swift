//
//  Team.swift
//  Swim-A-Thon
//
//  Created by Brame, Tony on 4/22/26.
//

import Foundation

//TODO: make this a class, probably as simple as "Team.name", "Team.id". We can add the "type" I mentioned in the API itself or the "RemoteAPI" class.
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
