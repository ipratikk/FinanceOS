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
                    }) {
                        FDSPickerRow(option: option, variant: variant, isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                    if option.id != options.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .frame(width: 320, height: 300)
        .background(AppColors.base)
    }

    private var triggerView: some View {
        Button(action: { isOpen.toggle() }) {
            FDSGlassSurface(elevation: .chip, cornerRadius: AppRadius.md) {
                HStack(spacing: AppSpacing.compact) {
                    if let selectedValue = selection,
                       let selectedOption = options.first(where: { ($0.value as? V) == selectedValue })
                    {
                        FDSPickerRow(option: selectedOption, variant: variant, isSelected: true)
                            .padding(.vertical, AppSpacing.compact)
                            .padding(.horizontal, AppSpacing.md)
                    } else {
                        HStack(spacing: AppSpacing.compact) {
                            FDSLabel(placeholder, style: .hint)
                            Spacer()
                        }
                        .padding(.vertical, AppSpacing.compact)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.trailing, AppSpacing.compact)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// Preview disabled due to generic type constraints
