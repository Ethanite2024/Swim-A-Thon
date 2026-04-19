//
//  RemoteAPI.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/19/26.
//

import Foundation
import SwiftData
import SwiftUI
class RemoteAPI {
    @AppStorage("remoteAPI") static var remoteAPI: URL = URL(string: "https://swimathon-api.placeholder.com/")!
    func getRemoteAPI() -> URL {
        return Self.remoteAPI
    }
}
