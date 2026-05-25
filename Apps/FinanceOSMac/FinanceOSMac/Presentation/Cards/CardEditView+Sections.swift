import FinanceCore
import FinanceUI
import SwiftUI

extension CardEditView {
    // MARK: - Left Hero Panel

    var heroPanelSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            Spacer()

            VStack(alignment: .leading, spacing: AppSpacing.compact) {
                FDSLabel(titleText)
                    .font(AppTypography.headingXL)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel(subtitleText)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(AppColors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CardDisplayPreview(
                cardName: selectedCatalogCard?.name,
                cardNickName: form.customName,
                bankName: form.selectedBank?.displayName,
                selectedBank: form.selectedBank,
                cardholderName: form.cardholderName,
                cardNetwork: form.cardType,
                first4: form.first4,
                last4: form.last4,
                bankLogo: form.selectedBank?.logoAssetName
            )

            HStack(spacing: AppSpacing.md) {
                securityBadge(icon: "lock.shield.fill", label: "PCI COMPLIANT")
                securityBadge(icon: "lock.fill", label: "AES-256 ENCRYPTION")
                Spacer()
            }

            Spacer()
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
    }

    private func securityBadge(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(AppTypography.captionSmMedium)
                .foregroundStyle(AppColors.accent)
            FDSLabel(label)
                .font(AppTypography.captionSm)
                .tracking(0.8)
                .foregroundStyle(AppColors.Text.secondary)
        }
    }

    // MARK: - Right Panel Header

    var headerBar: some View {
        HStack {
            FDSLabel("EDIT CONFIGURATION")
                .font(AppTypography.captionSm)
                .tracking(1.2)
                .foregroundStyle(AppColors.accent)
            Spacer()
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundStyle(AppColors.Text.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(AppColors.Glass.thinTint))
            })
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
    }

    // MARK: - Scroll Content

    var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if isCard {
                    catalogModeTabs
                    if catalogMode { catalogPickerSection }
                    cardCommonFields
                    bankSurface
                    securityChip
                } else {
                    accountBasicFields
                    bankSurface
                    if isEdit { dangerZoneSection }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Catalog / Manual Toggle

    var catalogModeTabs: some View {
        FDSChoiceGroup(
            selection: Binding(
                get: { catalogMode ? "CATALOG" : "MANUAL" },
                set: { catalogMode = $0 == "CATALOG" }
            ),
            options: ["CATALOG", "MANUAL"],
            optionLabel: { $0 }
        )
    }

    // MARK: - Catalog Picker

    var catalogPickerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            FDSLabel("SELECT & BROWSE CARDS")
                .font(AppTypography.captionSm)
                .tracking(1.0)
                .foregroundStyle(AppColors.Text.secondary)

            Button(action: { showCardSelection = true }, label: {
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: "magnifyingglass")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.tertiary)
                    FDSLabel(catalogPickerLabel)
                        .font(AppTypography.bodyMd)
                        .foregroundStyle(form.cardProductId.isEmpty ? AppColors.Text.tertiary : AppColors.Text.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTypography.captionSmMedium)
                        .foregroundStyle(AppColors.Text.tertiary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.compact)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(AppColors.Glass.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .strokeBorder(AppColors.border, lineWidth: 0.5)
                )
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
        }
    }

    private var catalogPickerLabel: String {
        guard let card = selectedCatalogCard else { return "Select a card..." }
        return card.issuer.isEmpty ? card.name : "\(card.issuer) - \(card.name)"
    }

    // MARK: - Card Common Fields

    var cardCommonFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            inputField("CARD NICKNAME", placeholder: "e.g. Primary Travel Card", text: $form.nickname)
            inputField("CARDHOLDER NAME", placeholder: "Full name on card", text: $form.cardholderName)
            HStack(spacing: AppSpacing.md) {
                inputField("FIRST 4 DIGITS", placeholder: "4242", text: $form.first4)
                    .frame(maxWidth: .infinity)
                inputField("LAST 4 DIGITS", placeholder: "9012", text: $form.last4)
                    .frame(maxWidth: .infinity)
                    .onChange(of: form.last4) { _, newValue in
                        if newValue.count > 4 { form.last4 = String(newValue.prefix(4)) }
                    }
            }
            networkPickerRow
        }
    }

    private var networkPickerRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            FDSLabel("CARD NETWORK")
                .font(AppTypography.captionSm)
                .tracking(1.0)
                .foregroundStyle(AppColors.Text.secondary)
            FDSPicker(
                selection: Binding<CardNetwork?>(
                    get: { form.cardType },
                    set: { if let net = $0 { form.cardType = net } }
                ),
                options: cardTypeOptions,
                variant: .symbolText,
                placeholder: "Select"
            )
        }
    }

    // MARK: - Account Fields

    var accountBasicFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            inputField("ACCOUNT NAME", placeholder: "Optional", text: $form.customName)
            inputField("ACCOUNT HOLDER", placeholder: "Full name", text: $form.cardholderName)
            inputField("LAST 4 DIGITS", placeholder: "XXXX", text: $form.last4)
                .onChange(of: form.last4) { _, newValue in
                    if newValue.count > 4 { form.last4 = String(newValue.prefix(4)) }
                }
            accountTypeField()
        }
    }

    var bankSurface: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            FDSLabel("BANK")
                .font(AppTypography.captionSm)
                .tracking(1.0)
                .foregroundStyle(AppColors.Text.secondary)
            bankField()
        }
    }

    // MARK: - Security Chip

    var securityChip: some View {
        HStack(alignment: .top, spacing: AppSpacing.compact) {
            Image(systemName: "lock.shield")
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.accent)
                .padding(.top, 1)
            FDSLabel(
                "Full card numbers are never stored on our servers. We use localized encryption for secure display."
            )
            .font(AppTypography.captionSm)
            .foregroundStyle(AppColors.Text.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(AppColors.accent.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .strokeBorder(AppColors.accent.opacity(0.18), lineWidth: 0.5)
        )
    }

    // MARK: - Danger Zone

    var dangerZoneSection: some View {
        FDSLiquidButton("Delete Account", leadingIcon: "trash.fill", variant: .danger) {
            showDeleteConfirm = true
        }
    }

    // MARK: - Footer

    var footerBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.md) {
                    if isEdit, isCard {
                        FDSLiquidButton(
                            "Delete Card",
                            leadingIcon: "trash",
                            variant: .danger,
                            fullWidth: true,
                            action: { showDeleteConfirm = true }
                        )
                    }
                    primaryActionButton
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
        }
    }

    @ViewBuilder var primaryActionButton: some View {
        switch mode {
        case let .edit(card, context):
            FDSLiquidButton("Save", trailingIcon: "arrow.right", variant: .primary, fullWidth: true) {
                Task {
                    await commitEdit(card: card, context: context)
                    dismiss()
                }
            }
            .disabled(form.last4.trimmingCharacters(in: .whitespaces).isEmpty)
        case let .createCard(_, onCommit), let .createAccount(_, onCommit):
            FDSLiquidButton("Create", trailingIcon: "arrow.right", variant: .primary, fullWidth: true) {
                onCommit(buildCreationState())
                dismiss()
            }
            .disabled(form.last4.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Card Selection Sheet

    var cardSelectionSheet: some View {
        CardSelectionView(
            onSelect: { card in
                if form.customName.trimmingCharacters(in: .whitespaces).isEmpty {
                    form.customName = card.name
                }
                form.cardType = card.cardType
                form.cardProductId = card.id
                form.selectedBank = Banks.allCases.first { bank in
                    card.issuer.localizedCaseInsensitiveContains(bank.displayName) ||
                        bank.displayName.localizedCaseInsensitiveContains(card.issuer)
                }
                showCardSelection = false
            },
            onDismiss: { showCardSelection = false }
        )
        .frame(minWidth: 700, maxHeight: 500)
    }
}
