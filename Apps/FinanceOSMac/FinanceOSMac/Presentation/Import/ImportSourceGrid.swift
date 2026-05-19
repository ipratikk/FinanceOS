import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportSourceGrid: View {
    let sources: [StatementSource]
    let selectedSource: StatementSource?
    let onSelectSource: (StatementSource) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(sources, id: \.self) { source in
                ImportSourceCard(
                    source: source,
                    matchedBank: Banks.matching(bankName: source.bankName),
                    isSelected: selectedSource == source,
                    onSelect: onSelectSource
                )
            }
        }
    }
}

private extension Banks {
    static func matching(bankName: String) -> Banks? {
        Banks.allCases.first { bank in
            bank.shortCode.lowercased() == bankName.lowercased()
                || bank.displayName.lowercased().contains(bankName.lowercased())
        }
    }
}

#Preview {
    @Previewable @State var selected: StatementSource?

    ImportSourceGrid(
        sources: StatementSource.allCases,
        selectedSource: selected,
        onSelectSource: { selected = $0 }
    )
    .padding()
    .background(AppColors.base)
}
