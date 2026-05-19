import SwiftUI

/// 20×20 radio button.
///
/// Off: recessed dark well. On: filled accent + white dot.
public struct FDSRadio: View {
    @Binding var isSelected: Bool

    public init(isSelected: Binding<Bool>) {
        _isSelected = isSelected
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color(red: 1.0, green: 0.62, blue: 0.04) : Color.black.opacity(0.25))
                .overlay {
                    Circle()
                        .strokeBorder(
                            isSelected
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
                                    colors: [.clear, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                            lineWidth: 1
                        )
                }

            if isSelected {
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 20, height: 20)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isSelected = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        FDSRadio(isSelected: .constant(false))
        FDSRadio(isSelected: .constant(true))
    }
    .padding()
}
