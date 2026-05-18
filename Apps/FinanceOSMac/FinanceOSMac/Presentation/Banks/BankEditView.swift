import FinanceCore
import FinanceUI
import SwiftUI

struct BankEditView: View {
    let bank: Bank
    let context: BankEditContext
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false
    @State private var showLinkSheet = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    linkedLedgersSection
                    deleteSection
                }
                .padding(AppSpacing.xl)
            }
        }
        .frame(width: 480, height: 520)
        .background(AppColors.base)
        .task { await context.loadLedgers(bankId: bank.id) }
        .alert("Delete Bank?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteBank(id: bank.id)
                    if context.error == nil { dismiss() }
                }
            }
        } message: {
            Text("This will delete this bank and all associated cards, accounts, and transactions.")
        }
        .alert("Error", isPresented: Binding(
            get: { context.error != nil },
            set: { if !$0 { context.clearError() } }
        )) {
            Button("OK") { context.clearError() }
        } message: {
            if let error = context.error { Text(error) }
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSImage(
                imageName: bank.symbolAssetName,
                fallbackSymbol: "building.columns.fill",
                height: 32,
                width: 32
            )
            VStack(alignment: .leading, spacing: 0) {
                Text(bank.name).bodyMedium()
                Text(bank.providerType.rawValue.capitalized)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: { showLinkSheet = true }) {
                Image(systemName: "plus")
                    .labelSmall()
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(AppColors.accent.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .help("Link Card or Account")
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .labelSmall()
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .padding(AppSpacing.md)
    }

    private var linkedLedgersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            let cards = context.linkedLedgers.filter { $0.kind == .creditCard }
            let accounts = context.linkedLedgers.filter { $0.kind == .bankAccount }

            if !cards.isEmpty {
                FDSSectionHeader("Cards")
                ledgerList(cards, symbol: "creditcard.fill")
            }

            if !accounts.isEmpty {
                FDSSectionHeader("Accounts")
                ledgerList(accounts, symbol: "banknote.fill")
            }

            if context.linkedLedgers.isEmpty {
                VStack(spacing: AppSpacing.compact) {
                    Image(systemName: "creditcard")
                        .font(AppTypography.displayLargeLight)
                        .foregroundStyle(.tertiary)
                    Text("No linked cards or accounts")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(.tertiary)
                    Text("Tap + to link a card or account")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(.quaternary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            }
        }
    }

    private func ledgerList(_ ledgers: [Ledger], symbol: String) -> some View {
        VStack(spacing: AppSpacing.compact) {
            ForEach(ledgers) { ledger in
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: symbol)
                        .font(AppTypography.captionLgSemibold)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(ledger.displayName).bodyMedium()
                        if !ledger.last4.isEmpty {
                            Text("•••• \(ledger.last4)")
                                .font(AppTypography.captionSm)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                        }
                }
            }
        }
    }

    private var deleteSection: some View {
        Button(action: { showDeleteConfirm = true }) {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: "trash.fill")
                    .font(AppTypography.captionLgSemibold)
                Text("Delete Bank")
                    .caption()
                Spacer()
            }
            .foregroundStyle(AppColors.debit)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppColors.debit.opacity(0.12))
            }
        }
        .buttonStyle(.plain)
    }
}
