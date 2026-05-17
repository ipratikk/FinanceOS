import FinanceCore
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
            Text("FinanceOS")
                .headingLarge()
            Text("Financial Operating System")
                .labelSmall()
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

                        Text(item.label)
                            .bodyLarge()

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
            Text("Quick Access")
                .captionLarge()

            let accounts = ledgers.filter { $0.kind == .bankAccount }
            let cards = ledgers.filter { $0.kind == .creditCard }

            if !accounts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accounts")
                        .labelSmall()
                        .foregroundColor(.gray)

                    ForEach(accounts.prefix(3), id: \.id) { account in
                        HStack(spacing: 8) {
                            Image(systemName: "building.2")
                                .labelSmall()
                                .foregroundColor(.gray)
                            Text(account.nickname.isEmpty ? account.displayName : account.nickname)
                                .labelSmall()
                                .lineLimit(1)
                        }
                        .foregroundColor(.gray)
                    }
                }
            }

            if !cards.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cards")
                        .labelSmall()
                        .foregroundColor(.gray)

                    ForEach(cards.prefix(3), id: \.id) { card in
                        HStack(spacing: 8) {
                            Image(systemName: "creditcard")
                                .labelSmall()
                                .foregroundColor(.gray)
                            Text(card.nickname.isEmpty ? card.displayName : card.nickname)
                                .labelSmall()
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

                Text("Import Statement")
                    .bodyLarge()

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
