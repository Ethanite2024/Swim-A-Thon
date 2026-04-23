//
//  App.swift
//  APIExamples
//
//  Created by Brame, Tony on 4/22/26.
//

class SwimApp {
    
    static func doTheThing() async throws {
        
        let tigerSharks: Team = .init(name: "Tiger Sharks!");
        
        let tony: Swimmer = .init(name: "TonyPG");
        let ethan: Swimmer = .init(name: "EthanPG");
        
        //just showing the JSON conversion of an object (the classes inherited this method from JSONObject)
        print(tigerSharks.toJSON()!);
        print(tony.toJSON()!);
        print(ethan.toJSON()!);
        
        //sending this data to an API.
        //things here could be different - i.e. we could send an array of swimmers or teams, etc.
        //this is just demonstrating a save event, NOT a load event (e.g. loading a list of teams when the app loads)
        try await SwimAPIController.sendSwimmer(data: tony);
        try await SwimAPIController.sendSwimmer(data: ethan);
        try await SwimAPIController.sendTeam(data: tigerSharks);
    }
}
