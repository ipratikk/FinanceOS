import FinanceCore
import FinanceUI
import SwiftUI

struct ImportStatementHeading: View {
    let fileURLs: [URL]
    let ledgerName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Importing \(fileName)")
                .font(AppTypography.headingSmall)
                .foregroundColor(DesignTokens.Text.primary)

            if let ledgerName {
                Text("into \(ledgerName)")
                    .font(AppTypography.bodySm)
                    .foregroundColor(AppColors.accent)
            } else {
                Text("Select destination below")
                    .font(AppTypography.bodySm)
                    .foregroundColor(DesignTokens.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(DesignTokens.Background.surfaceGlass)
        .cornerRadius(AppRadius.sm)
    }

    private var fileName: String {
        if fileURLs.count == 1 {
            return fileURLs.first?.lastPathComponent ?? "Statement"
        }
        return "\(fileURLs.count) files"
    }
}

#Preview {
    VStack(spacing: 12) {
        ImportStatementHeading(
            fileURLs: [URL(fileURLWithPath: "/path/to/HDFC-statement.csv")],
            ledgerName: "HDFC Account"
        )
        ImportStatementHeading(
            fileURLs: Array(repeating: URL(fileURLWithPath: "/path/to/file.csv"), count: 3),
            ledgerName: "Multiple Ledgers"
        )
        ImportStatementHeading(
            fileURLs: [URL(fileURLWithPath: "/path/to/file.csv")],
            ledgerName: nil
        )
    }
    .padding()
}
