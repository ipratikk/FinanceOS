import FinanceCore
@testable import FinanceOSMac
import Foundation
import XCTest

private actor FakeParser: StatementParsingProtocol {
    private var callCount = 0
    private let requiresPassword: Bool
    private let correctPassword: String

    init(requiresPassword: Bool, correctPassword: String = "secret123") {
        self.requiresPassword = requiresPassword
        self.correctPassword = correctPassword
    }

    func parse(fileURL: URL, password: String?) async throws -> ParsedStatement {
        callCount += 1
        if requiresPassword, password != correctPassword {
            throw TransactionImportError.passwordProtected(fileURL.lastPathComponent)
        }
        return ParsedStatement(bankName: "HDFC", accountName: "Test", accountLast4: "1234")
    }
}

private final class FakePasswordStore: ImportPasswordStoring {
    var savedPasswords: [UUID: String] = [:]

    func password(for ledgerId: UUID) -> String? {
        savedPasswords[ledgerId]
    }

    func save(_ password: String, for ledgerId: UUID) {
        savedPasswords[ledgerId] = password
    }
}

@MainActor
final class ImportViewModelPasswordTests: XCTestCase {
    func test_no_password_needed_parses_immediately() async throws {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: false)
        )
        let statement = try await viewModel.parseWithPasswordRetry(
            fileURL: URL(fileURLWithPath: "/tmp/statement.pdf"),
            parser: FakeParser(requiresPassword: false)
        )
        XCTAssertEqual(statement.bankName, "HDFC")
        XCTAssertNil(viewModel.pendingPasswordRequest)
    }

    func test_locked_file_prompts_then_resolves_on_correct_password() async throws {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: true)
        )
        let fileURL = URL(fileURLWithPath: "/tmp/statement.pdf")

        async let result = viewModel.parseWithPasswordRetry(
            fileURL: fileURL,
            parser: FakeParser(requiresPassword: true)
        )

        // Wait for the prompt to appear, then submit the correct password.
        while viewModel.pendingPasswordRequest == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        let request = try XCTUnwrap(viewModel.pendingPasswordRequest)
        XCTAssertFalse(request.isRetry)
        request.onSubmit("secret123", false)

        let statement = try await result
        XCTAssertEqual(statement.bankName, "HDFC")
    }

    func test_wrong_password_reprompts_with_isRetry_true() async throws {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: true)
        )
        let fileURL = URL(fileURLWithPath: "/tmp/statement.pdf")

        async let result = viewModel.parseWithPasswordRetry(
            fileURL: fileURL,
            parser: FakeParser(requiresPassword: true)
        )

        while viewModel.pendingPasswordRequest == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        viewModel.pendingPasswordRequest?.onSubmit("wrongpassword", false)

        while viewModel.pendingPasswordRequest == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        let retryRequest = try XCTUnwrap(viewModel.pendingPasswordRequest)
        XCTAssertTrue(retryRequest.isRetry)
        retryRequest.onSubmit("secret123", false)

        let statement = try await result
        XCTAssertEqual(statement.bankName, "HDFC")
    }

    func test_cancel_throws_passwordProtected() async {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: true)
        )
        let fileURL = URL(fileURLWithPath: "/tmp/statement.pdf")

        async let result: Void = {
            _ = try await viewModel.parseWithPasswordRetry(fileURL: fileURL, parser: FakeParser(requiresPassword: true))
        }()

        while viewModel.pendingPasswordRequest == nil {
            try? await Task.sleep(for: .milliseconds(10))
        }
        viewModel.pendingPasswordRequest?.onCancel()

        do {
            try await result
            XCTFail("expected passwordProtected to be thrown")
        } catch TransactionImportError.passwordProtected {
            // expected
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func test_known_ledger_checks_keychain_before_prompting() async throws {
        let ledgerId = UUID()
        let passwordStore = FakePasswordStore()
        passwordStore.save("secret123", for: ledgerId)

        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            initialTarget: .ledger(ledgerId),
            fileParser: FakeParser(requiresPassword: true),
            passwordStore: passwordStore
        )
        let statement = try await viewModel.parseWithPasswordRetry(
            fileURL: URL(fileURLWithPath: "/tmp/statement.pdf"),
            parser: FakeParser(requiresPassword: true)
        )

        XCTAssertEqual(statement.bankName, "HDFC")
        XCTAssertNil(viewModel.pendingPasswordRequest, "should never have prompted — Keychain had it")
    }

    func test_save_to_keychain_flushes_once_target_is_known() async throws {
        // Regression test: the "Save to Keychain" toggle records intent at prompt time
        // (requestPassword), but the target ledger usually isn't resolved yet at that
        // point — the write must happen later, once it is (flushPendingKeychainSaves).
        // Without the fix this asserts, the write never happens at all.
        let passwordStore = FakePasswordStore()
        let ledgerId = UUID()
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            fileParser: FakeParser(requiresPassword: true),
            passwordStore: passwordStore
        )
        let fileURL = URL(fileURLWithPath: "/tmp/statement.pdf")

        async let result = viewModel.parseWithPasswordRetry(
            fileURL: fileURL,
            parser: FakeParser(requiresPassword: true)
        )

        while viewModel.pendingPasswordRequest == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        // saveToKeychain: true — but no target is resolved yet at this point.
        viewModel.pendingPasswordRequest?.onSubmit("secret123", true)
        _ = try await result

        XCTAssertNil(passwordStore.password(for: ledgerId), "not written yet — no target resolved")

        // Simulate target resolution (what auto-match/manual-pick does) and flush.
        viewModel.selectedTarget = .ledger(ledgerId)
        viewModel.flushPendingKeychainSaves()

        XCTAssertEqual(passwordStore.password(for: ledgerId), "secret123")
    }
}
