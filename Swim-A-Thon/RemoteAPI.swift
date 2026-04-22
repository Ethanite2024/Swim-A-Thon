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
    
    //shell for now TODO: complete send, build into UI (probably a submit button?)
    func sendData()
    {
       //get an http object
        //assign URL to http object
        //assign payload to http body
        //execute http.post() method
        //porocess the response
        
    }
    
    // Make Swimmer Data into JSON
    //TODO: methods like this should accept a "Swimmer" object, not individual fields. Also,I would move this code to the Swimmer object itself (probably using Encodable extension, but not required)
    func convertSwimmerDataToJSON(swimmerName: String, swimmerId: UUID, swimmerLaps: Int) -> Data? {
        let payload: [String: Any] = [
            "name": swimmerName,
            "id": swimmerId.uuidString,
            "laps": swimmerLaps
        ]
        /// Example Return Output: {"name":"John Dart","id":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","laps":20}
        return try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
    }
}
