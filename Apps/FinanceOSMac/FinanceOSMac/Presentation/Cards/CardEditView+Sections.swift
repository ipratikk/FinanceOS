import FinanceCore
import FinanceUI
import SwiftUI

extension CardEditView {
    // MARK: - Left Hero Panel

    var heroPanelSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            Spacer()

            VStack(alignment: .leading, spacing: AppSpacing.compact) {
                FDSLabel(viewModel.titleText)
                    .font(AppTypography.headingXL)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel(viewModel.subtitleText)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(AppColors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CardDisplayPreview(
                cardName: viewModel.selectedCatalogCard?.name,
                cardNickName: viewModel.form.customName,
                bankName: viewModel.form.selectedBank?.displayName,
                selectedBank: viewModel.form.selectedBank,
                cardholderName: viewModel.form.cardholderName,
                cardNetwork: viewModel.form.cardType,
                first4: viewModel.form.first4,
                last4: viewModel.form.last4,
                bankLogo: viewModel.form.selectedBank?.logoAssetName
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
                if viewModel.isCard {
                    catalogModeTabs
                    if viewModel.catalogMode { catalogPickerSection }
                    cardCommonFields
                    bankSurface
                    securityChip
                } else {
                    accountBasicFields
                    bankSurface
                    if viewModel.isEdit { dangerZoneSection }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Catalog / Manual Toggle

    var catalogModeTabs: some View {
        FDSChoiceGroup(
            selection: Binding(
                get: { viewModel.catalogMode ? "CATALOG" : "MANUAL" },
                set: { viewModel.catalogMode = $0 == "CATALOG" }
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

            Button(action: { viewModel.showCardSelection = true }, label: {
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: "magnifyingglass")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.tertiary)
                    FDSLabel(catalogPickerLabel)
                        .font(AppTypography.bodyMd)
                        .foregroundStyle(
                            viewModel.form.cardProductId.isEmpty ? AppColors.Text.tertiary : AppColors.Text.primary
                        )
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
        guard let card = viewModel.selectedCatalogCard else { return "Select a card..." }
        return card.issuer.isEmpty ? card.name : "\(card.issuer) - \(card.name)"
    }

    // MARK: - Card Common Fields

    var cardCommonFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            inputField("CARD NICKNAME", placeholder: "e.g. Primary Travel Card", text: $viewModel.form.nickname)
            inputField("CARDHOLDER NAME", placeholder: "Full name on card", text: $viewModel.form.cardholderName)
            HStack(spacing: AppSpacing.md) {
                inputField("FIRST 4 DIGITS", placeholder: "4242", text: $viewModel.form.first4)
                    .frame(maxWidth: .infinity)
                inputField("LAST 4 DIGITS", placeholder: "9012", text: $viewModel.form.last4)
                    .frame(maxWidth: .infinity)
                    .onChange(of: viewModel.form.last4) { _, newValue in
                        if newValue.count > 4 { viewModel.form.last4 = String(newValue.prefix(4)) }
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
                    get: { viewModel.form.cardType },
                    set: { if let net = $0 { viewModel.form.cardType = net } }
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
            inputField("ACCOUNT NAME", placeholder: "Optional", text: $viewModel.form.customName)
            inputField("ACCOUNT HOLDER", placeholder: "Full name", text: $viewModel.form.cardholderName)
            inputField("LAST 4 DIGITS", placeholder: "XXXX", text: $viewModel.form.last4)
                .onChange(of: viewModel.form.last4) { _, newValue in
                    if newValue.count > 4 { viewModel.form.last4 = String(newValue.prefix(4)) }
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
            viewModel.showDeleteConfirm = true
        }
    }

    // MARK: - Footer

    var footerBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.md) {
                    if viewModel.isEdit, viewModel.isCard {
                        FDSLiquidButton(
                            "Delete Card",
                            leadingIcon: "trash",
                            variant: .danger,
                            fullWidth: true,
                            action: { viewModel.showDeleteConfirm = true }
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
        if viewModel.isEdit {
            FDSLiquidButton("Save", trailingIcon: "arrow.right", variant: .primary, fullWidth: true) {
                Task { await viewModel.commitEdit() }
            }
            .disabled(viewModel.form.last4.trimmingCharacters(in: .whitespaces).isEmpty)
        } else {
            FDSLiquidButton("Create", trailingIcon: "arrow.right", variant: .primary, fullWidth: true) {
                viewModel.triggerCreate()
            }
            .disabled(viewModel.form.last4.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Card Selection Sheet

    var cardSelectionSheet: some View {
        CardSelectionView(
            onSelect: { card in
                if viewModel.form.customName.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.form.customName = card.name
                }
                viewModel.form.cardType = card.cardType
                viewModel.form.cardProductId = card.id
                viewModel.form.selectedBank = Banks.allCases.first { bank in
                    card.issuer.localizedCaseInsensitiveContains(bank.displayName) ||
                        bank.displayName.localizedCaseInsensitiveContains(card.issuer)
                }
                viewModel.showCardSelection = false
            },
            onDismiss: { viewModel.showCardSelection = false }
        )
        .frame(minWidth: 700, maxHeight: 500)
    }
}
