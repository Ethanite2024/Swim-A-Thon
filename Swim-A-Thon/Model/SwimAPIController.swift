//
//  SwimAPIController.swift
//  APIExamples
//
//  Created by Brame, Tony on 4/22/26.
//

import Foundation

class SwimAPIController {
    
    static func sendSwimmer(data: Swimmer) async throws {
        try await sendData(json: data.toJSON())
    }
    
    static func sendTeam(data: Team) async throws {
        try await sendData(json: data.toJSON())
    }
    
    static func sendData(json: String?) async throws {
        
            // 1. Prepare the URL
            guard let url = URL(string: "https://swimathonapitesttony.azurewebsites.net/api/submitresults") else {
                throw URLError(.badURL)
            }

            // 2. Configure the Request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json?.data(using: .utf8)

            // 4. Send the Data
            let (data, response) = try await URLSession.shared.data(for: request)

            // 5. Validate the Response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            print("Success! Data sent.")
    }
}
