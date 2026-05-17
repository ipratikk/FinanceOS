import FinanceCore
import FinanceUI
import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavigationItem?
    @State private var ledgers: [Ledger] = []

    private let appContainer = AppContainer.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        mainNavigation

                        Divider()
                            .padding(.vertical, 8)

                        quickAccess
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                Spacer()

                footer
            }
            .background(AppColors.surface)
            .task {
                await loadAccounts()
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            FDSLabel("FinanceOS", style: .headingLarge)
            FDSLabel("Financial Operating System", style: .hint)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.base)
    }

    var mainNavigation: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(NavigationItem.allCases, id: \.self) { item in
                Button(action: { selection = item }, label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .headingSmall()
                            .frame(width: 20)

                        FDSLabel(item.label, style: .bodyLarge)

                        Spacer()
                    }
                    .foregroundColor(selection == item ? .white : .gray)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(selection == item ? AppColors.accent.opacity(0.2) : Color
                        .clear)
                    .cornerRadius(AppRadius.md)
                })
            }
        }
    }

    var quickAccess: some View {
        VStack(alignment: .leading, spacing: 8) {
            FDSLabel("Quick Access", style: .subheading)

            let accounts = ledgers.filter { $0.kind == .bankAccount }
            let cards = ledgers.filter { $0.kind == .creditCard }

            if !accounts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Accounts", style: .hint)

                    ForEach(accounts.prefix(3), id: \.id) { account in
                        HStack(spacing: 8) {
                            Image(systemName: "building.2")
                                .labelSmall()
                                .foregroundColor(.gray)
                            FDSLabel(
                                account.nickname.isEmpty ? account.displayName : account.nickname,
                                style: .labelSmall
                            )
                            .lineLimit(1)
                        }
                        .foregroundColor(.gray)
                    }
                }
            }

            if !cards.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Cards", style: .hint)

                    ForEach(cards.prefix(3), id: \.id) { card in
                        HStack(spacing: 8) {
                            Image(systemName: "creditcard")
                                .labelSmall()
                                .foregroundColor(.gray)
                            FDSLabel(card.nickname.isEmpty ? card.displayName : card.nickname, style: .hint)
                                .lineLimit(1)
                        }
                        .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    var footer: some View {
        Button(action: { selection = .importStatement }, label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.doc.fill")
                    .headingSmall()

                FDSLabel("Import Statement", style: .bodyLarge)

                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppColors.accent)
            .cornerRadius(AppRadius.md)
        })
        .padding(AppSpacing.md)
    }

    private func loadAccounts() async {
        do {
            ledgers = try await appContainer.ledgerRepository.fetchLedgers()
        } catch {
            print("Error loading sidebar data: \(error)")
        }
    }
}

#Preview {
    @Previewable @State var selection: NavigationItem? = .dashboard
    return SidebarView(selection: $selection)
}
