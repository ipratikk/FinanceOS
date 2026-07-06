@testable import FinanceOSMac
import XCTest

final class ImportPasswordStoreTests: XCTestCase {
    // Isolated service identifier — never touches the real app's Keychain entries.
    private let store = ImportPasswordStore(serviceIdentifier: "com.financeos.import.pdfpassword.test")
    private let ledgerId = UUID()

    override func tearDown() {
        // Best-effort cleanup so repeated test runs don't accumulate stale items.
        store.delete(for: ledgerId)
        super.tearDown()
    }

    func test_returns_nil_when_nothing_saved() {
        XCTAssertNil(store.password(for: ledgerId))
    }

    func test_saves_and_retrieves_a_password() {
        store.save("hunter2", for: ledgerId)
        XCTAssertEqual(store.password(for: ledgerId), "hunter2")
    }

    func test_save_overwrites_an_existing_entry() {
        store.save("first", for: ledgerId)
        store.save("second", for: ledgerId)
        XCTAssertEqual(store.password(for: ledgerId), "second")
    }
}
