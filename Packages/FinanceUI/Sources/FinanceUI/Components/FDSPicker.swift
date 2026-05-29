import FinanceCore
import SwiftUI

/// Popover-based picker with optional logo, symbol, or text-only row variants.
///
/// Trigger appears as a styled input field. Selection drives a popover list of `FDSPickerOption`
/// rows. Use `FDSSelect` for simpler native-menu use cases.
public struct FDSPicker<V: Hashable>: View {
    /// Currently selected value; `nil` shows the placeholder.
    @Binding var selection: V?
    /// Array of options to display in the popover list.
    let options: [FDSPickerOption]
    /// Controls how each option row is rendered (logo, symbol+text, or text only).
    let variant: FDSPickerVariant
    /// Text displayed in the trigger when no option is selected.
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
                    .font(AppTypography.captionSmMedium)
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
