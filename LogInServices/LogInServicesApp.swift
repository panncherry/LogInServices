//
//  LogInServicesApp.swift
//  LogInServices
//
//  Created by Pann Cherry on 4/4/26.
//

import SwiftUI

@main
struct LogInServicesApp: App {
    @StateObject private var session = AppDependencies.makeSessionCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
        }
    }
}
