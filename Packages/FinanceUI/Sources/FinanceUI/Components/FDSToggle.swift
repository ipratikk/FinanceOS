import FinanceCore
import SwiftUI

/// Apple-spec toggle (36×22 capsule).
///
/// Off: dark well + inner shadow. On: green fill + gleam, knob slides right.
/// Knob: 16×16 white circle with subtle inset highlight.
public struct FDSToggle: View {
    @Binding var isOn: Bool

    public init(isOn: Binding<Bool>) {
        _isOn = isOn
    }

    public var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color.black.opacity(0.25))
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isOn
                                ? LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.16),
                                        Color.white.opacity(0.06),
                                        .clear,
                                        Color.black.opacity(0.20)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                            lineWidth: 1
                        )
                }

            HStack {
                if !isOn {
                    Spacer()
                }

                Circle()
                    .fill(Color.white)
                    .frame(width: AppSpacing.md, height: AppSpacing.md)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.30),
                                        Color.black.opacity(0.10)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }

                if isOn {
                    Spacer()
                }
            }
            .padding(3)
        }
        .frame(width: 36, height: 22)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isOn.toggle()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            Text("Auto-deduplicate")
            Spacer()
            FDSToggle(isOn: .constant(false))
        }

        HStack {
            Text("Preview before import")
            Spacer()
            FDSToggle(isOn: .constant(true))
        }
    }
    .padding()
}
