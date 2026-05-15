//
//  PasswordPromptSheet.swift
//  FinanceOS
//
//  Created by Pratik Goel on 15/05/26.
//

import SwiftUI

struct PasswordPromptSheet: View {
    @State private var password = ""
    @State private var saveToKeychain = false
    let filename: String
    let isPasswordInvalid: Bool
    let onCancel: () -> Void
    let onSubmit: (String, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("PDF Password") {
                    Text("The file \"\(filename)\" is password-protected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isPasswordInvalid ? Color.red : Color.clear, lineWidth: 2)
                            )

                        if isPasswordInvalid {
                            Text("Incorrect password. Please try again.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Section {
                    Toggle("Save password to Keychain", isOn: $saveToKeychain)
                        .font(.caption)
                }
            }
            .navigationTitle("Enter Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        onSubmit(password, saveToKeychain)
                    }
                    .disabled(password.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
