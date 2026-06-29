import FinanceCore
import FinanceOSAPI
import Foundation
import Observation

@Observable
@MainActor
final class CategoryCorrectionViewModel {
    private let transaction: FinanceCore.Transaction?
    private let originalCategoryId: String?
    private let onCorrected: ((UUID, String) -> Void)?
    private let graphQLClient: ApolloGraphQLClient

    var selectedCategoryId: String
    var isSaving = false

    init(
        transaction: FinanceCore.Transaction,
        currentCategoryId: String?,
        graphQLClient: ApolloGraphQLClient,
        onCorrected: ((UUID, String) -> Void)?
    ) {
        self.transaction = transaction
        self.graphQLClient = graphQLClient
        originalCategoryId = currentCategoryId
        self.onCorrected = onCorrected
        selectedCategoryId = currentCategoryId ?? "uncategorized"
    }

    init(row: TransactionRow, graphQLClient: ApolloGraphQLClient, onCorrected: ((UUID, String) -> Void)?) {
        transaction = row.sourceTransaction
        self.graphQLClient = graphQLClient
        originalCategoryId = row.categoryId
        self.onCorrected = onCorrected
        selectedCategoryId = row.categoryId ?? "uncategorized"
    }

    var isSaveDisabled: Bool {
        isSaving || selectedCategoryId == originalCategoryId
    }

    func save(onDismiss: @escaping () -> Void) async {
        guard let txn = transaction else { return }
        isSaving = true
        do {
            _ = try await graphQLClient.perform(
                mutation: RecategorizeMutation(
                    transactionId: txn.id.uuidString,
                    category: selectedCategoryId
                )
            )
            onCorrected?(txn.id, selectedCategoryId)
        } catch {
            FinanceLogger.userInterface.logError("Failed to save category correction", caughtError: error, [:])
        }
        isSaving = false
        onDismiss()
    }
}
