import Foundation
import Security

/// Persists PDF-statement passwords in the macOS Keychain, keyed by ledger id, so a
/// user isn't re-prompted every time they import from an account they've already
/// unlocked once. Injected as a protocol so `ImportViewModel` tests can fake it.
protocol ImportPasswordStoring {
    func password(for ledgerId: String) -> String?
    func save(_ password: String, for ledgerId: String)
}

struct ImportPasswordStore: ImportPasswordStoring {
    private let serviceIdentifier: String

    init(serviceIdentifier: String = "com.financeos.import.pdfpassword") {
        self.serviceIdentifier = serviceIdentifier
    }

    func password(for ledgerId: String) -> String? {
        var query = baseQuery(for: ledgerId)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func save(_ password: String, for ledgerId: String) {
        let data = Data(password.utf8)
        let query = baseQuery(for: ledgerId)

        var attributesToUpdate: [String: Any] = [:]
        attributesToUpdate[kSecValueData as String] = data
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func delete(for ledgerId: String) {
        SecItemDelete(baseQuery(for: ledgerId) as CFDictionary)
    }

    private func baseQuery(for ledgerId: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: ledgerId
        ]
    }
}
