import FinanceCore
import FinanceUI
import SwiftUI

struct LedgerEditView: View {
    let ledger: Ledger
    let ledgerRepository: any LedgerRepository
    let bankRepository: any BankRepository

    @State private var displayName: String
    @State private var last4: String
    @State private var nickname: String
    @State private var bankId: UUID
    @State private var ownerName: String
    @State private var accountType: String
    @State private var cardType: String
    @State private var linkedLedgerId: UUID?

    @State private var banks: [Bank] = []
    @State private var linkedLedgers: [Ledger] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    @Environment(\.dismiss) var dismiss

    init(
        ledger: Ledger,
        ledgerRepository: any LedgerRepository,
        bankRepository: any BankRepository
    ) {
        self.ledger = ledger
        self.ledgerRepository = ledgerRepository
        self.bankRepository = bankRepository
        _displayName = State(initialValue: ledger.displayName)
        _last4 = State(initialValue: ledger.last4)
        _nickname = State(initialValue: ledger.nickname)
        _bankId = State(initialValue: ledger.bankId)
        _ownerName = State(initialValue: ledger.ownerName)
        _accountType = State(initialValue: ledger.accountType ?? "savings")
        _cardType = State(initialValue: ledger.cardType ?? "other")
        _linkedLedgerId = State(initialValue: ledger.linkedLedgerId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Edit \(ledger.kind.displayName)")
                    .headingMedium()
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .headingSmall()
                        .foregroundStyle(AppColors.textSecondary)
                })
                .accessibilityLabel("Close")
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(ledger.kind.displayName) Information")
                            .captionLarge()
                            .foregroundStyle(AppColors.textSecondary)

                        VStack(spacing: 8) {
                            inputField("Display Name", text: $displayName)
                            inputField("Last 4 Digits", text: $last4)
                                .onChange(of: last4) { _, newValue in
                                    if newValue.count > 4 {
                                        last4 = String(newValue.prefix(4))
                                    }
                                }

                            if ledger.kind == .bankAccount {
                                inputField("Owner Name", text: $ownerName)

                                VStack(alignment: .leading, spacing: 4) {
                                    FDSLabel("Account Type", style: .hint)
                                    FDSPicker(
                                        selection: Binding(
                                            get: { accountType },
                                            set: { if let value = $0 { accountType = value } }
                                        ),
                                        options: [
                                            FDSPickerOption(
                                                id: "savings",
                                                value: "savings",
                                                title: "Savings",
                                                symbol: "building.columns.fill"
                                            ),
                                            FDSPickerOption(
                                                id: "checking",
                                                value: "checking",
                                                title: "Checking",
                                                symbol: "checkmark.rectangle.fill"
                                            ),
                                            FDSPickerOption(
                                                id: "credit",
                                                value: "credit",
                                                title: "Credit",
                                                symbol: "creditcard.fill"
                                            )
                                        ],
                                        variant: .symbolText,
                                        placeholder: "Select type"
                                    )
                                }
                            }

                            if ledger.kind == .creditCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    FDSLabel("Card Type", style: .hint)
                                    FDSPicker(
                                        selection: Binding(
                                            get: { cardType },
                                            set: { if let value = $0 { cardType = value } }
                                        ),
                                        options: [
                                            FDSPickerOption(
                                                id: "credit",
                                                value: "credit",
                                                title: "Credit",
                                                symbol: "creditcard.fill"
                                            ),
                                            FDSPickerOption(
                                                id: "debit",
                                                value: "debit",
                                                title: "Debit",
                                                symbol: "creditcard"
                                            ),
                                            FDSPickerOption(
                                                id: "other",
                                                value: "other",
                                                title: "Other",
                                                symbol: "questionmark.circle"
                                            )
                                        ],
                                        variant: .symbolText,
                                        placeholder: "Select type"
                                    )
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bank\(ledger.kind == .creditCard ? " & Account" : "")")
                            .captionLarge()
                            .foregroundStyle(AppColors.textSecondary)

                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                FDSLabel("Bank", style: .hint)
                                FDSPicker(
                                    selection: Binding(
                                        get: { bankId },
                                        set: { if let value = $0 { bankId = value } }
                                    ),
                                    options: banks.map { bank in
                                        FDSPickerOption(
                                            id: bank.id,
                                            value: bank.id,
                                            title: bank.name,
                                            imageName: bank.symbolAssetName
                                        )
                                    },
                                    variant: .symbolText,
                                    placeholder: "Select bank"
                                )
                            }

                            if ledger.kind == .creditCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    FDSLabel("Linked Account", style: .hint)
                                    FDSPicker(
                                        selection: $linkedLedgerId,
                                        options: {
                                            var options = [FDSPickerOption(
                                                id: "none",
                                                value: nil as UUID?,
                                                title: "None",
                                                symbol: "minus.circle"
                                            )]
                                            options += linkedLedgers.map { acct in
                                                FDSPickerOption(
                                                    id: acct.id,
                                                    value: UUID?(acct.id),
                                                    title: acct.displayName,
                                                    symbol: "banknote.fill"
                                                )
                                            }
                                            return options
                                        }(),
                                        variant: .symbolText,
                                        placeholder: "Select account"
                                    )
                                }
                            }

                            inputField("Nickname (Optional)", text: $nickname)
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(spacing: 8) {
                        Button(action: { showDeleteConfirm = true }, label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .labelSmall()
                                Text("Delete \(ledger.kind.displayName)")
                                    .bodyLarge()
                                Spacer()
                            }
                            .foregroundColor(AppColors.debit)
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.debit.opacity(0.1))
                            .cornerRadius(AppRadius.md)
                        })
                    }
                }
                .padding(AppSpacing.md)
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: { dismiss() }, label: {
                    FDSLabel("Cancel", style: .bodyLarge)
                        .frame(maxWidth: .infinity)
                })
                .foregroundStyle(AppColors.textSecondary)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: {
                    Task {
                        await saveLedger()
                    }
                }, label: {
                    FDSLabel("Save", style: .monoAmount)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(AppColors.textPrimary)
                })
                .padding(AppSpacing.sm)
                .background(AppColors.accent)
                .cornerRadius(AppRadius.md)
                .disabled(isLoading)
            }
            .padding(AppSpacing.md)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.base)
        .onAppear {
            Task {
                await loadData()
            }
        }
        .alert("Operation Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .alert("Delete \(ledger.kind.displayName)?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteLedger()
                }
            }
        } message: {
            Text(
                "This will permanently delete this \(ledger.kind.displayName.lowercased()) and all associated transactions. This cannot be undone."
            )
        }
    }

    private func loadData() async {
        do {
            banks = try await bankRepository.fetchBanks()
            if ledger.kind == .creditCard {
                linkedLedgers = try await ledgerRepository.fetchLedgers(kind: .bankAccount)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveLedger() async {
        do {
            isLoading = true
            let updated = Ledger(
                id: ledger.id,
                bankId: bankId,
                kind: ledger.kind,
                displayName: displayName,
                last4: last4,
                nickname: nickname,
                ownerName: ownerName,
                createdAt: ledger.createdAt,
                accountType: ledger.kind == .bankAccount ? accountType : nil,
                cardType: ledger.kind == .creditCard ? cardType : nil,
                cardProduct: ledger.cardProduct,
                linkedLedgerId: ledger.kind == .creditCard ? linkedLedgerId : nil,
                isArchived: ledger.isArchived
            )
            try await ledgerRepository.update(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func deleteLedger() async {
        do {
            isLoading = true
            try await ledgerRepository.delete(id: ledger.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label, style: .hint)
            FDSTextInput("", text: text, style: .bodyMedium)
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }
}
