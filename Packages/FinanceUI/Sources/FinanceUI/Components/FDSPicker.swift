import FinanceCore
import SwiftUI

public struct FDSPicker<V: Hashable>: View {
    @Binding var selection: V?
    let options: [FDSPickerOption]
    let variant: FDSPickerVariant
    let placeholder: String
    @State private var isOpen = false

    public init(
        selection: Binding<V?>,
        options: [FDSPickerOption],
        variant: FDSPickerVariant = .symbolText,
        placeholder: String = "Select..."
    ) {
        _selection = selection
        self.options = options
        self.variant = variant
        self.placeholder = placeholder
    }

    public var body: some View {
        triggerView
            .popover(isPresented: $isOpen) {
                optionsList
            }
    }

    private var optionsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(options) { option in
                    let isSelected = selection == (option.value as? V)
                    Button(action: {
                        selection = option.value as? V
                        isOpen = false
                    }, label: {
                        FDSPickerRow(option: option, variant: variant, isSelected: isSelected)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    })
                    .buttonStyle(.plain)
                    if option.id != options.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
        .frame(width: 320, height: 300)
        .background(AppColors.base)
    }

    private var triggerView: some View {
        Button(action: { isOpen.toggle() }, label: {
            HStack(spacing: AppSpacing.compact) {
                if let selectedValue = selection,
                   let selectedOption = options.first(where: { ($0.value as? V) == selectedValue }) {
                    FDSPickerRow(option: selectedOption, variant: variant, isSelected: false)
                } else {
                    FDSLabel(placeholder, style: .hint)
                    Spacer()
                }

                Image(systemName: "chevron.up.chevron.down")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.trailing, AppSpacing.compact)
            }
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .strokeBorder(AppColors.textPrimary.opacity(0.06), lineWidth: 0.5)
                    }
            }
        })
        .buttonStyle(.plain)
    }
}

// Preview disabled due to generic type constraints
