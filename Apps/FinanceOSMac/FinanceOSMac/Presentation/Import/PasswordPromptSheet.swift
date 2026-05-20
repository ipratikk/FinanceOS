//
//  PasswordPromptSheet.swift
//  FinanceOS
//
//  Created by Pratik Goel on 15/05/26.
//

import FinanceCore
import FinanceUI
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
                    Group {
                        FDSLabel("The file \"\(filename)\" is password-protected.", style: .caption)

                        VStack(alignment: .leading, spacing: 4) {
                            FDSTextInput("Password", text: $password, style: .bodyMedium, isSecure: true)
                                .textFieldStyle(.roundedBorder)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isPasswordInvalid ? AppColors.debit : AppColors.clear, lineWidth: 2)
                                )

                            if isPasswordInvalid {
                                FDSLabel("Incorrect password. Please try again.", style: .caption)
                            }
                        }
                    }
                }

                Section {
                    Toggle("Save password to Keychain", isOn: $saveToKeychain)
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
