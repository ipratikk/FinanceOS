import FinanceCore
import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavigationItem?
    @State private var accounts: [Account] = []
    @State private var cards: [Card] = []

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
                .font(.system(size: 20, weight: .bold))
            Text("Financial Operating System")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
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
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 20)

                        Text(item.label)
                            .font(.system(size: 14, weight: .medium))

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
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)

            if !accounts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accounts")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.gray)

                    ForEach(accounts.prefix(3), id: \.id) { account in
                        HStack(spacing: 8) {
                            Image(systemName: "building.2")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                            Text(account.nickname.isEmpty ? account.accountName : account.nickname)
                                .font(.system(size: 12, weight: .regular))
                                .lineLimit(1)
                        }
                        .foregroundColor(.gray)
                    }
                }
            }

            if !cards.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cards")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.gray)

                    ForEach(cards.prefix(3), id: \.id) { card in
                        HStack(spacing: 8) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                            Text(card.nickname.isEmpty ? card.cardName : card.nickname)
                                .font(.system(size: 12, weight: .regular))
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
                    .font(.system(size: 16, weight: .semibold))

                Text("Import Statement")
                    .font(.system(size: 14, weight: .medium))

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
            accounts = try await appContainer.accountRepository.fetchAccounts()
            cards = try await appContainer.cardRepository.fetchCards()
        } catch {
            print("Error loading sidebar data: \(error)")
        }
    }
}

#Preview {
    @Previewable @State var selection: NavigationItem? = .dashboard
    return SidebarView(selection: $selection)
}
