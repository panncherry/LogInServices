//
//  HomeView.swift
//  LogInServices
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionCoordinator

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Welcome")
                    .font(.title2.weight(.semibold))
                Text("You are signed in.")
                    .foregroundStyle(.secondary)
                Button("Sign Out") {
                    Task { await session.logout() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}
