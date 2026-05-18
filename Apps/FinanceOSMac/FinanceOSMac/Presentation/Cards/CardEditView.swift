import FinanceCore
import FinanceUI
import SwiftUI

struct CardEditView: View {
    let card: Ledger
    let context: CardEditContext
    @State private var last4: String
    @State private var cardType: String
    @State private var nickname: String
    @State private var bankId: UUID
    @State private var linkedLedgerId: UUID?
    @State private var cardProduct: String?
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false
    @State private var showCardSelection = false

    private var selectedCatalogCard: CardMetadata? {
        guard let cardProduct else { return nil }
        return CardDatabase.supportedCards().first { $0.id == cardProduct }
    }

    private var bankName: String? {
        guard let bank = context.banks.first(where: { $0.id == bankId }) else { return nil }
        return bank.name
    }

    init(card: Ledger, context: CardEditContext) {
        self.card = card
        self.context = context
        _last4 = State(initialValue: card.last4)
        _cardType = State(initialValue: card.cardType ?? "other")
        _nickname = State(initialValue: card.nickname.isEmpty ? card.displayName : card.nickname)
        _bankId = State(initialValue: card.bankId)
        _linkedLedgerId = State(initialValue: card.linkedLedgerId)
        _cardProduct = State(initialValue: card.cardProduct)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    cardSection
                    bankSection
                    deleteSection
                }
                .padding(AppSpacing.xl)
            }

            Divider().opacity(0.3)
            footer
        }
        .frame(width: 540, height: 720)
        .background(AppColors.base)
        .alert("Delete Card?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteCard(id: card.id)
                    if context.deleteError == nil { dismiss() }
                }
            }
        } message: {
            Text("This will permanently delete this card and all associated transactions.")
        }
        .alert("Delete Failed", isPresented: Binding(
            get: { context.deleteError != nil },
            set: { if !$0 { context.clearError() } }
        )) {
            Button("OK") { context.clearError() }
        } message: {
            if let error = context.deleteError {
                Text(error)
            }
        }
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView(
                onSelect: { selected in
                    cardType = selected.cardType
                    cardProduct = selected.id
                    showCardSelection = false
                },
                onDismiss: { showCardSelection = false }
            )
            .frame(minWidth: 520, minHeight: 600)
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSMerchantAvatar(name: card.displayName, symbol: "creditcard.fill", size: 32)
            VStack(alignment: .leading, spacing: 0) {
                Text("Edit Card")
                    .bodyMedium()
                Text(card.displayName)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
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

    private var cardSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("CARD INFORMATION")
                    .font(AppTypography.labelSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                catalogCardWidget

                field("Nickname") { FDSTextInput("e.g. Travel Card", text: $nickname) }

                FDSCreditCardDisplay(
                    cardName: selectedCatalogCard?.name,
                    bankName: bankName,
                    cardNetwork: cardType,
                    encryptedCardNumber: .constant(""),
                    last4: $last4
                )

                fieldWithAction(
                    "Card Network",
                    actionLabel: "Auto-detect",
                    actionDisabled: last4.trimmingCharacters(in: .whitespaces).count < 4,
                    action: autoDetectCardType
                ) {
                    let cardTypeOptions = CardNetwork.allCases.map { network in
                        FDSPickerOption(
                            id: network.rawValue,
                            value: network.rawValue,
                            title: network.displayName,
                            symbol: network.symbolAssetName == nil ? "creditcard.fill" : nil,
                            imageName: network.symbolAssetName
                        )
                    }
                    FDSPicker(
                        selection: Binding(
                            get: { cardType },
                            set: { if let value = $0 { cardType = value } }
                        ),
                        options: cardTypeOptions,
                        variant: .symbolText,
                        placeholder: "Select network"
                    )
                }
            }
        }
    }

    @ViewBuilder private var catalogCardWidget: some View {
        if let catalogCard = selectedCatalogCard {
            HStack(spacing: AppSpacing.md) {
                catalogArtwork(catalogCard)
                VStack(alignment: .leading, spacing: 3) {
                    Text(catalogCard.name)
                        .font(AppTypography.bodySmSemibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    catalogNetworkBadge(catalogCard.cardType)
                }
                Spacer(minLength: AppSpacing.compact)
                Button("Change") { showCardSelection = true }
                    .font(AppTypography.captionSmMedium)
                    .foregroundStyle(AppColors.accent)
                    .buttonStyle(.plain)
                Button { cardProduct = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.quaternary)
                }
                .buttonStyle(.plain)
            }
            .padding(AppSpacing.compact)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColors.accent.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .strokeBorder(AppColors.accent.opacity(0.2), lineWidth: 0.5)
                    )
            }
        } else {
            Button(action: { showCardSelection = true }) {
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: "creditcard.fill").labelSmall()
                    Text("Browse Card Database").labelSmall()
                    Spacer()
                    Image(systemName: "chevron.right").font(AppTypography.labelSemibold)
                }
                .foregroundStyle(AppColors.accent)
                .padding(.horizontal, AppSpacing.compact)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var bankSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("BANK & ACCOUNT")
                    .font(AppTypography.labelSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                field("Bank") {
                    let bankOptions = context.banks.map { bank in
                        FDSPickerOption(
                            id: bank.id,
                            value: bank.id,
                            title: bank.name,
                            imageName: bank.symbolAssetName
                        )
                    }
                    FDSPicker(
                        selection: Binding(
                            get: { bankId },
                            set: { if let value = $0 { bankId = value } }
                        ),
                        options: bankOptions,
                        variant: .symbolText,
                        placeholder: "Select bank"
                    )
                }
                field("Linked Account") {
                    let filtered = context.accounts.filter { $0.bankId == bankId }
                    let allOptions: [FDSPickerOption] = {
                        var options = [FDSPickerOption(
                            id: "none",
                            value: nil as UUID?,
                            title: "None",
                            symbol: "minus.circle"
                        )]
                        options += filtered.map { account in
                            FDSPickerOption(
                                id: account.id,
                                value: account.id,
                                title: account.displayName,
                                symbol: "banknote.fill"
                            )
                        }
                        return options
                    }()
                    return FDSPicker(
                        selection: $linkedLedgerId,
                        options: allOptions,
                        variant: .symbolText,
                        placeholder: "Select account"
                    )
                }
            }
        }
    }

    private var deleteSection: some View {
        Button(action: { showDeleteConfirm = true }) {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: "trash.fill")
                    .font(AppTypography.captionLgSemibold)
                Text("Delete Card")
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

    private var footer: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSLiquidButton("Cancel", variant: .subtle) { dismiss() }
            Spacer()
            FDSLiquidButton("Save", variant: .primary) {
                Task {
                    let derivedName = selectedCatalogCard?.name ?? (nickname.isEmpty ? card.displayName : nickname)
                    let updated = Ledger(
                        id: card.id,
                        bankId: bankId,
                        kind: card.kind,
                        displayName: derivedName,
                        last4: last4,
                        nickname: nickname,
                        ownerName: card.ownerName,
                        createdAt: card.createdAt,
                        accountType: card.accountType,
                        cardType: cardType,
                        cardProduct: cardProduct,
                        linkedLedgerId: linkedLedgerId,
                        isArchived: card.isArchived
                    )
                    await context.updateCard(updated)
                    if context.deleteError == nil { dismiss() }
                }
            }
        }
        .padding(AppSpacing.md)
    }

    private func autoDetectCardType() {
        cardType = BINParser.detectCardType(from: last4)
    }

    private func field(
        _ label: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text(label.uppercased())
                .font(AppTypography.labelSemibold)
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            content()
        }
    }

    private func fieldWithAction(
        _ label: String,
        actionLabel: String,
        actionDisabled: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            HStack {
                Text(label.uppercased())
                    .font(AppTypography.labelSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button(actionLabel, action: action)
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(actionDisabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(AppColors.accent))
                    .disabled(actionDisabled)
                    .buttonStyle(.plain)
            }
            content()
        }
    }
}

private extension CardEditView {
    func catalogArtwork(_ card: CardMetadata) -> some View {
        Group {
            if let urlString = card.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case let .success(image) = phase { image.resizable().scaledToFit() }
                    else { catalogArtworkPlaceholder }
                }
            } else {
                catalogArtworkPlaceholder
            }
        }
        .frame(width: 72, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(
            Color.white.opacity(0.12),
            lineWidth: 0.5
        ) }
    }

    var catalogArtworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: "creditcard.fill").font(AppTypography.headlineSmLight).foregroundStyle(.tertiary)
            }
    }

    func catalogNetworkBadge(_ type: String) -> some View {
        Text(type.uppercased())
            .font(AppTypography.iconSm).tracking(0.4)
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background { Capsule(style: .continuous).fill(AppColors.accent.opacity(0.12)) }
    }
}
