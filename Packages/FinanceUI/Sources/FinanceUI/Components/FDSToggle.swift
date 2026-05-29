import FinanceCore
import SwiftUI

/// Apple-spec toggle (36×22 capsule).
///
/// Off: dark well + inner shadow. On: green fill + gleam, knob slides right.
/// Knob: 16×16 white circle with subtle inset highlight.
public struct FDSToggle: View {
    @Binding var isOn: Bool
    /// VoiceOver label (e.g. "Auto-deduplicate"). Falls back to "Toggle" if empty.
    let label: String
    /// When false, renders at 40% opacity and ignores taps.
    let isEnabled: Bool

    public init(isOn: Binding<Bool>, label: String = "", isEnabled: Bool = true) {
        _isOn = isOn
        self.label = label
        self.isEnabled = isEnabled
    }

    public var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? AppColors.accent : AppColors.Glass.inputWell)
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isOn
                                ? AppColors.Glass.gleamBorder
                                : LinearGradient(
                                    colors: [.clear, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                            lineWidth: 1
                        )
                }

            HStack {
                if !isOn { Spacer() }

                Circle()
                    .fill(AppColors.textPrimary)
                    .frame(width: AppSpacing.md, height: AppSpacing.md)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        AppColors.textPrimary.opacity(0.30),
                                        AppColors.base.opacity(0.10)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }

                if isOn { Spacer() }
            }
            .padding(3)
        }
        .frame(width: 36, height: 22)
        .opacity(isEnabled ? 1.0 : 0.4)
        .disabled(!isEnabled)
        .onTapGesture {
            guard isEnabled else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isOn.toggle()
            }
        }
        .accessibilityLabel(label.isEmpty ? "Toggle" : label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            FDSLabel("Auto-deduplicate")
            Spacer()
            FDSToggle(isOn: .constant(false), label: "Auto-deduplicate")
        }

        HStack {
            FDSLabel("Preview before import")
            Spacer()
            FDSToggle(isOn: .constant(true), label: "Preview before import")
        }

        HStack {
            FDSLabel("Disabled toggle")
            Spacer()
            FDSToggle(isOn: .constant(true), label: "Disabled toggle", isEnabled: false)
        }
    }
    .padding()
}
