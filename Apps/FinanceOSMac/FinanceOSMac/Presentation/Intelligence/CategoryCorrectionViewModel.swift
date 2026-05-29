import FinanceCore
import FinanceIntelligence
import Foundation
import Observation

@Observable
@MainActor
final class CategoryCorrectionViewModel {
    private let transaction: FinanceCore.Transaction?
    private let previousPrediction: CategoryPrediction?
    private let originalCategoryId: String?
    private let onCorrected: ((UUID, String) -> Void)?

    var selectedCategoryId: String
    var isSaving = false

    init(
        transaction: FinanceCore.Transaction,
        currentCategoryId: String?,
        previousPrediction: CategoryPrediction?,
        onCorrected: ((UUID, String) -> Void)?
    ) {
        self.transaction = transaction
        self.previousPrediction = previousPrediction
        originalCategoryId = currentCategoryId
        self.onCorrected = onCorrected
        selectedCategoryId = currentCategoryId ?? "uncategorized"
    }

    init(row: TransactionRow, onCorrected: ((UUID, String) -> Void)?) {
        transaction = row.sourceTransaction
        previousPrediction = nil
        originalCategoryId = row.categoryId
        self.onCorrected = onCorrected
        selectedCategoryId = row.categoryId ?? "uncategorized"
    }

    var isSaveDisabled: Bool {
        isSaving || selectedCategoryId == originalCategoryId
    }

    func save(
        intelligence: (any TransactionIntelligenceService)?,
        onDismiss: @escaping () -> Void
    ) async {
        guard let txn = transaction else { return }
        isSaving = true
        if let service = intelligence {
            try? await service.learn(
                transaction: txn,
                correctedCategoryId: selectedCategoryId,
                correctedMerchant: nil,
                previousPrediction: previousPrediction
            )
        }
        onCorrected?(txn.id, selectedCategoryId)
        isSaving = false
        onDismiss()
    }
}
