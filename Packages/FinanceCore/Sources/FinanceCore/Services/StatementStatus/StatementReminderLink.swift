import Foundation

/// Deep links that hand a statement reminder (notification or widget tap) to the app's normal import flow.
/// Format: `financeos://import/<ledger-uuid>`. The link only selects the import target;
/// the upload itself still goes through ``ImportView`` and `uploadStatement`.
public enum StatementReminderLink {
    public static let scheme = "financeos"
    static let importHost = "import"

    public static func importURL(for ledgerId: UUID) -> URL? {
        URL(string: "\(scheme)://\(importHost)/\(ledgerId.uuidString)")
    }

    /// Returns the import target for a `financeos://import/<uuid>` link, or nil for anything else.
    public static func importTarget(from url: URL) -> TransactionImportTarget? {
        guard url.scheme?.lowercased() == scheme,
              url.host?.lowercased() == importHost,
              let idText = url.pathComponents.dropFirst().first,
              url.pathComponents.count == 2,
              let ledgerId = UUID(uuidString: idText)
        else { return nil }
        return .ledger(ledgerId)
    }
}
