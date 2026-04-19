//
//  RemoteAPI.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/19/26.
//

import Foundation
import SwiftData
import SwiftUI

struct RemoteAPI {
    /// This Is a Placeholder API URL
    @AppStorage("remoteAPI") static var remoteAPI: URL = URL(string: "https://swimathon-api.placeholder.com/")!
    
    func getRemoteAPI() -> URL {
        return Self.remoteAPI
    }
    
    // Make Swimmer Data into JSON
    func convertSwimmerDataToJSON(swimmerName: String, swimmerId: UUID, swimmerLaps: Int) -> Data? {
        let payload: [String: Any] = [
            "name": swimmerName,
            "id": swimmerId.uuidString,
            "laps": swimmerLaps
        ]
        // Example Return Output: {"name":"John Dart","id":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","laps":20}
        return try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
    }
}
