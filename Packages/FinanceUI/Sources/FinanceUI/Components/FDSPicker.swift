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

    private var hasSelection: Bool {
        guard let selectedValue = selection else { return false }
        return options.contains { ($0.value as? V) == selectedValue }
    }

    private var triggerView: some View {
        Button(action: { isOpen.toggle() }, label: {
            HStack(spacing: AppSpacing.compact) {
                if let selectedValue = selection,
                   let selectedOption = options.first(where: { ($0.value as? V) == selectedValue }) {
                    FDSPickerRow(option: selectedOption, variant: variant, isSelected: false)
                } else {
                    FDSLabel(placeholder)
                        .font(AppTypography.bodyMd)
                        .foregroundStyle(AppColors.Text.tertiary)
                    Spacer()
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.Text.tertiary)
            }
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(AppColors.Glass.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .strokeBorder(
                                isOpen ? AppColors.Border.focus : AppColors.Border.input,
                                lineWidth: isOpen ? 1.5 : 0.5
                            )
                    }
            }
        })
        .buttonStyle(.plain)
        .animation(AppAnimation.easeSmooth, value: isOpen)
    }
}

// Preview disabled due to generic type constraints
