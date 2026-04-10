//
//  RootView.swift
//  LogInServices
//
//  Chooses login vs home from `SessionCoordinator.phase`. Launch restoration runs in `.task`
//  so the first frame can show a deterministic loading state without blocking UIKit/SwiftUI init.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionCoordinator

    var body: some View {
        Group {
            switch session.phase {
            case .bootstrapping:
                ProgressView("Loading…")
            case .unauthenticated:
                LoginView()
            case .authenticated:
                HomeView()
            }
        }
        .animation(.default, value: session.phase)
        .task {
            await session.restoreSessionOnLaunch()
        }
    }
}
