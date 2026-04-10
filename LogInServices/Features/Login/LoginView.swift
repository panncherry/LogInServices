//
//  LoginView.swift
//  LogInServices
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionCoordinator
    @StateObject private var model = LoginViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $model.email)
                        .textContentType(.username)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
#endif
                    SecureField("Password", text: $model.password)
                        .textContentType(.password)
                }
                if let message = model.errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
                Section {
                    Button {
                        Task { await model.signIn(session: session) }
                    } label: {
                        if model.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(model.isLoading)
                }
            }
            .navigationTitle("Sign In")
        }
    }
}
