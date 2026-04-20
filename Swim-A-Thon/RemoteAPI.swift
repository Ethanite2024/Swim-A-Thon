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
    /// The remote API I belive Is the Server name URL if it is then here is the server database name
    @AppStorage("remoteAPI") static var remoteAPI: URL = URL(string: "tiger-sharks--database--swim-a-thon.database.windows.net")!
    
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
