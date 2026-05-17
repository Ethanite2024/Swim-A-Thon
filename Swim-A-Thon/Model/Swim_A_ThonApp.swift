//
//  Swim_A_ThonApp.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 6/24/25.
//

import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct Swim_A_ThonApp: App {
    /// Google is Signed in
    @State private var isSignedIn: Bool = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Swimmer.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LapCounterView()
                .environment(\.isSignedIn, $isSignedIn)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
