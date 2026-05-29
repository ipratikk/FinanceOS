import FinanceCore
import SwiftUI

/// Input field with floating label, focus border, and validation states.
///
/// Replicates PDSTextInput floating-label pattern:
/// - Label starts inside the field as bodyMd placeholder text
/// - On focus or input: label instantly shrinks to captionSm and Y-offset animates up
/// - TextField fades in below the floated label
/// - Border thickens and turns accent on focus
///
/// States: `.normal` / `.error(String)` / `.success`
/// Validation state for `FDSInputField`. The `.error` case carries the message string.
public enum FDSInputState: Equatable {
    case normal
    case error(String)
    case success
}

public struct FDSInputField: View {
    let label: String
    /// Shown inside the field when the label is in resting (non-floated) state.
    let placeholder: String
    /// Helper or error message displayed below the field. Overridden by `.error` state message.
    let helper: String?
    let state: FDSInputState
    let isSecure: Bool
    @Binding var text: String

    @FocusState private var isFocused: Bool
    @State private var labelSmall = false // font: instant switch, no animation
    @State private var labelFloated = false // Y offset: animated

    private static let fieldHeight: CGFloat = 56
    private static let hPad: CGFloat = AppSpacing.compact
    private static let vPad: CGFloat = AppSpacing.compact
    private static let labelRestingOffset: CGFloat = 10 // push label down to visual center

    public init(
        _ label: String,
        text: Binding<String>,
        placeholder: String = "",
        helper: String? = nil,
        state: FDSInputState = .normal,
        isSecure: Bool = false
    ) {
        self.label = label
        _text = text
        self.placeholder = placeholder
        self.helper = helper
        self.state = state
        self.isSecure = isSecure
    }

    private var isFloated: Bool {
        isFocused || !text.isEmpty
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            ZStack(alignment: .topLeading) {
                fieldBackground
                fieldContent
            }
            .frame(height: Self.fieldHeight)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }

            if let message = statusMessage {
                FDSLabel(message)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(messageColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.horizontal, Self.hPad)
            }
        }
        .animation(AppAnimation.easeSmooth, value: state)
        .onChange(of: isFloated) { _, floated in
            // Font switch is instant (matches PDSFloatingLabel behavior)
            labelSmall = floated
            // Y offset animates
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                labelFloated = floated
            }
        }
        .onAppear {
            // Seed state for pre-filled values
            if isFloated {
                labelSmall = true
                labelFloated = true
            }
        }
    }

    // MARK: - Background

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
            .fill(AppColors.Glass.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
    }

    // MARK: - Label + Input content

    private var fieldContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Floating label — font switches instantly, offset animates
            FDSLabel(label)
                .font(labelSmall ? AppTypography.captionSm : AppTypography.bodyMd)
                .tracking(labelSmall ? 1.0 : 0)
                .foregroundStyle(labelColor)
                .offset(y: labelFloated ? 0 : Self.labelRestingOffset)
                .allowsHitTesting(false)

            // TextField — fades in when floated
            inputField
                .opacity(labelFloated ? 1 : 0)
        }
        .padding(.horizontal, Self.hPad)
        .padding(.top, Self.vPad)
    }

    @ViewBuilder private var inputField: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .font(AppTypography.bodyMd)
                .foregroundStyle(AppColors.Text.primary)
                .focused($isFocused)
                .textFieldStyle(.plain)
        } else {
            TextField(placeholder, text: $text)
                .font(AppTypography.bodyMd)
                .foregroundStyle(AppColors.Text.primary)
                .focused($isFocused)
                .textFieldStyle(.plain)
        }
    }

    // MARK: - Derived style

    private var labelColor: Color {
        if isFocused { return AppColors.accent }
        return labelSmall ? AppColors.Text.secondary : AppColors.Text.tertiary
    }

    private var borderColor: Color {
        if isFocused { return AppColors.Border.focus }
        switch state {
        case .normal, .success: return AppColors.Border.input
        case .error: return AppColors.danger.opacity(0.6)
        }
    }

    private var borderWidth: CGFloat {
        isFocused ? 1.5 : 0.5
    }

    private var statusMessage: String? {
        switch state {
        case .normal, .success: return helper
        case let .error(msg): return msg
        }
    }

    private var messageColor: Color {
        switch state {
        case .normal, .success: return AppColors.Text.tertiary
        case .error: return AppColors.danger
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var filled = "ICICI Amazon Pay"
    @Previewable @State var pwd = ""

    return VStack(spacing: 16) {
        FDSInputField("CARD NICKNAME", text: $name, placeholder: "e.g. Primary Travel Card")
        FDSInputField("CARDHOLDER NAME", text: $filled)
        FDSInputField("PASSWORD", text: $pwd, state: .error("Required"), isSecure: true)
    }
    .padding(AppSpacing.xl)
    .background(AppColors.base)
    .frame(width: 360)
}
