import FinanceCore
import SwiftUI

/// Day-of-month stepper with − | value | + controls.
///
/// Used for statement day and due day selection (1-31).
public struct FDSStepper: View {
    @Binding var value: Int
    let label: String
    /// Minimum allowed value (default 1, i.e. first day of month).
    let min: Int
    /// Maximum allowed value (default 31, i.e. last day of month).
    let max: Int

    public init(
        _ label: String,
        value: Binding<Int>,
        min: Int = 1,
        max: Int = 31
    ) {
        self.label = label
        _value = value
        self.min = min
        self.max = max
    }

    public var body: some View {
        HStack(spacing: 0) {
            Button(action: { if value > min { value -= 1 } }, label: {
                Image(systemName: "minus")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundColor(AppColors.Text.primary)
                    .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)
            })
            .buttonStyle(.plain)

            FDSLabel(String(format: "%02d", value))
                .font(AppTypography.bodySmSemibold)
                .foregroundColor(AppColors.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)

            Button(action: { if value < max { value += 1 } }, label: {
                Image(systemName: "plus")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundColor(AppColors.Text.primary)
                    .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)
            })
            .buttonStyle(.plain)
        }
        .background(AppColors.base.opacity(0.25))
        .cornerRadius(AppRadius.sm)
    }
}

#Preview {
    VStack(spacing: 16) {
        FDSStepper("Statement Day", value: .constant(15))
        FDSStepper("Due Day", value: .constant(5))
    }
    .padding()
}
