import Foundation

// MARK: - AsyncLoadable

/// Eliminates the repeated `isLoading = true; defer { isLoading = false }` boilerplate
/// across ViewModels. Conforming types get `withLoading(onError:_:)` for free.
protocol AsyncLoadable: AnyObject {
    var isLoading: Bool { get set }
}

extension AsyncLoadable {
    /// Wraps an async throwing operation with loading state management.
    /// Calls `onError` if the operation throws; swallows the error otherwise.
    func withLoading(onError: ((Error) -> Void)? = nil, _ operation: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            onError?(error)
        }
    }
}

// MARK: - DeletableViewModel

/// Eliminates the repeated `deleteError = nil; do { try await ...; await reload() } catch { deleteError = ... }`
/// pattern in ViewModels that support item deletion.
protocol DeletableViewModel: AnyObject {
    var deleteError: String? { get set }
}

extension DeletableViewModel {
    /// Performs an async delete operation, resetting `deleteError` on entry.
    /// - Parameters:
    ///   - operation: The async throwing delete work (repository call, pre/post logging, etc.)
    ///   - onError: Optional extra handling (e.g., logging) called before setting `deleteError`.
    ///   - onSuccess: Async reload or follow-up action called only when the operation succeeds.
    func performDelete(
        _ operation: () async throws -> Void,
        onError: ((Error) -> Void)? = nil,
        onSuccess: (() async -> Void)? = nil
    ) async {
        deleteError = nil
        do {
            try await operation()
            await onSuccess?()
        } catch {
            onError?(error)
            deleteError = error.localizedDescription
        }
    }
}
