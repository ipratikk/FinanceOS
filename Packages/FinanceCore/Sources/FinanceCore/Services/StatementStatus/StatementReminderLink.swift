import Foundation

/// Deep links that hand a statement reminder (notification or widget tap) to the app's normal import flow.
/// Format: `financeos://import/<ledger-id>` (ids are prefixed, e.g. `CC-1A2B3C4D`). The link only selects the import
/// target;
/// the upload itself still goes through ``ImportView`` and `uploadStatement`.
public enum StatementReminderLink {
    public static let scheme = "financeos"
    static let importHost = "import"

    public static func importURL(for ledgerId: String) -> URL? {
        URL(string: "\(scheme)://\(importHost)/\(ledgerId)")
    }

    /// Returns the import target for a `financeos://import/<ledger-id>` link, or nil for anything else.
    public static func importTarget(from url: URL) -> TransactionImportTarget? {
        guard url.scheme?.lowercased() == scheme,
              url.host?.lowercased() == importHost,
              let idText = url.pathComponents.dropFirst().first,
              url.pathComponents.count == 2,
              isLedgerId(idText)
        else { return nil }
        return .ledger(idText)
    }

    /// Backend ids are prefixed (`BA-1A2B3C4D`, `CC-1A2B3C4D`); legacy rows may still be plain UUIDs.
    static func isLedgerId(_ text: String) -> Bool {
        UUID(uuidString: text) != nil || text.wholeMatch(of: /[A-Z]{2,4}-[0-9A-F]{8}/) != nil
    }
}
