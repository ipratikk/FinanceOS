@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class PasswordPromptSheetSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_password_prompt_initial() {
        let view = PasswordPromptSheet(
            filename: "axis_statement.pdf",
            isPasswordInvalid: false,
            onCancel: {},
            onSubmit: { _, _ in }
        )
        verifyComponentSnapshots(view, size: CGSize(width: 480, height: 360))
    }

    func test_password_prompt_invalid() {
        let view = PasswordPromptSheet(
            filename: "axis_statement.pdf",
            isPasswordInvalid: true,
            onCancel: {},
            onSubmit: { _, _ in }
        )
        verifyComponentSnapshots(view, size: CGSize(width: 480, height: 360))
    }
}
