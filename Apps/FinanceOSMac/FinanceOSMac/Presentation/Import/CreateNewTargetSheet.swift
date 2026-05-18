import FinanceCore
import FinanceUI
import SwiftUI

struct CreateNewTargetSheet: View {
    @Binding var state: TargetCreationState
    let detectedBank: String
    let availableAccounts: [Ledger]
    let onCancel: () -> Void
    let onCreate: () -> Void

    @State private var showCardSelection = false

    var isCard: Bool {
        state.isCard
    }

    private var selectedCatalogCard: CardMetadata? {
        guard !state.cardProduct.isEmpty else { return nil }
        return CardDatabase.supportedCards().first { $0.id == state.cardProduct }
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
                Button { state.cardProduct = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTypography.bodyMd)
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
                    Image(systemName: "creditcard.fill").font(AppTypography.captionSmSemibold)
                    Text("Browse Card Database").font(AppTypography.captionLg)
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

    private func catalogArtwork(_ card: CardMetadata) -> some View {
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
        .frame(width: 56, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(
            Color.white.opacity(0.12),
            lineWidth: 0.5
        ) }
    }

    private var catalogArtworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: "creditcard.fill").font(AppTypography.bodyMdLight).foregroundStyle(.tertiary)
            }
    }

    private func catalogNetworkBadge(_ type: String) -> some View {
        Text(type.uppercased())
            .font(AppTypography.iconSm).tracking(0.4)
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background { Capsule(style: .continuous).fill(AppColors.accent.opacity(0.12)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                FDSLabel(isCard ? "Create New Card" : "Create New Account", style: .headingMedium)
                Spacer()
                Button(action: { onCancel() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .headingSmall()
                        .foregroundStyle(AppColors.textSecondary)
                })
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FDSGlassSurface(cornerRadius: AppRadius.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            FDSLabel("BASIC INFORMATION", style: .subheading)

                            VStack(spacing: AppSpacing.sm) {
                                if isCard {
                                    inputField("Card Name (Optional)", text: $state.customName)
                                    inputField("Nickname", text: $state.nickname)
                                    catalogCardWidget
                                    FDSCreditCardDisplay(
                                        cardName: selectedCatalogCard?.name,
                                        bankName: nil,
                                        cardNetwork: state.cardType,
                                        encryptedCardNumber: $state.encryptedCardNumber,
                                        last4: $state.last4
                                    )
                                    cardTypeField()
                                } else {
                                    inputField("Account Name (Optional)", text: $state.customName)
                                    inputField("Owner Name", text: $state.ownerName)
                                    inputField("Last 4 Digits", text: $state.last4)
                                        .onChange(of: state.last4) { _, newValue in
                                            if newValue.count > 4 {
                                                state.last4 = String(newValue.prefix(4))
                                            }
                                        }
                                    accountTypeField()
                                }
                            }
                        }
                    }

                    FDSGlassSurface(cornerRadius: AppRadius.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            FDSLabel("BANK & ACCOUNT", style: .subheading)

                            bankField()
                        }
                    }
                }
                .padding(AppSpacing.md)
            }

            Divider().opacity(0.3)

            HStack(spacing: AppSpacing.compact) {
                FDSLiquidButton("Cancel", variant: .subtle) { onCancel() }
                Spacer()
                FDSLiquidButton("Create", variant: .primary) { onCreate() }
                    .disabled(state.last4.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(AppSpacing.md)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.base)
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView(
                onSelect: { card in
                    if state.customName.trimmingCharacters(in: .whitespaces).isEmpty {
                        state.customName = card.name
                    }
                    state.cardType = card.cardType
                    state.cardProduct = card.id
                    showCardSelection = false
                },
                onDismiss: { showCardSelection = false }
            )
            .frame(minWidth: 520, minHeight: 600)
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

    private func autoDetectCardType() {
        let cardNumberToUse = !state.maskedCardNumber.isEmpty ? state.maskedCardNumber : state.last4
        let detectedType = BINParser.detectCardType(from: cardNumberToUse)
        state.cardType = detectedType
    }

    private func cardTypeField() -> some View {
        let cardTypeOptions = CardNetwork.allCases.map { network in
            FDSPickerOption(
                id: network.rawValue,
                value: network.rawValue,
                title: network.displayName,
                symbol: network.symbolAssetName == nil ? "creditcard.fill" : nil,
                imageName: network.symbolAssetName
            )
        }

        return VStack(alignment: .leading, spacing: AppSpacing.tight) {
            HStack {
                FDSLabel("Card Network", style: .hint)
                Spacer()
                Button(action: { autoDetectCardType() }) {
                    FDSLabel("Auto-detect", style: .caption, color: .secondary)
                }
                .disabled(state.last4.trimmingCharacters(in: .whitespaces).count < 4)
            }

            FDSPicker(
                selection: Binding(
                    get: { state.cardType },
                    set: { if let value = $0 { state.cardType = value } }
                ),
                options: cardTypeOptions,
                variant: .symbolText,
                placeholder: "Select network"
            )

            Button(action: { showCardSelection = true }) {
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: "creditcard.fill")
                        .font(AppTypography.captionSmSemibold)
                    FDSLabel("Browse Card Database", style: .bodyMedium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppTypography.labelSemibold)
                }
                .foregroundStyle(AppColors.accent)
                .padding(.horizontal, AppSpacing.compact)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func accountTypeField() -> some View {
        let accountTypeOptions = [
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
                id: "money_market",
                value: "money_market",
                title: "Money Market",
                symbol: "chart.line.uptrend.xyaxis"
            ),
            FDSPickerOption(
                id: "other",
                value: "other",
                title: "Other",
                symbol: "banknote.fill"
            )
        ]

        return VStack(alignment: .leading, spacing: AppSpacing.tight) {
            FDSLabel("Account Type", style: .hint)

            FDSPicker(
                selection: Binding(
                    get: { state.accountType },
                    set: { if let value = $0 { state.accountType = value } }
                ),
                options: accountTypeOptions,
                variant: .symbolText,
                placeholder: "Select type"
            )
        }
    }

    private func bankField() -> some View {
        let bankOptions = Banks.allCases.map {
            FDSPickerOption(id: $0.rawValue, value: $0, title: $0.displayName, imageName: $0.symbolAssetName)
        }
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel("Bank", style: .hint)
                FDSPicker(
                    selection: Binding(get: { state.selectedBank }, set: { state.selectedBank = $0 }),
                    options: bankOptions,
                    variant: .symbolText,
                    placeholder: detectedBank.isEmpty ? "Select bank" : "Detected: \(detectedBank)"
                )
            }
            if isCard, !availableAccounts.isEmpty {
                linkedAccountField
            }
        }
    }

    private var linkedAccountField: some View {
        let none = FDSPickerOption(id: "none", value: nil as UUID?, title: "None", symbol: "minus.circle")
        let options: [FDSPickerOption] = [none] + availableAccounts.map {
            FDSPickerOption(id: $0.id, value: UUID?($0.id), title: $0.displayName, symbol: "banknote.fill")
        }
        return VStack(alignment: .leading, spacing: AppSpacing.tight) {
            FDSLabel("Linked Account (Optional)", style: .hint)
            FDSPicker(
                selection: $state.linkedLedgerId,
                options: options,
                variant: .symbolText,
                placeholder: "Select account"
            )
        }
    }
}
