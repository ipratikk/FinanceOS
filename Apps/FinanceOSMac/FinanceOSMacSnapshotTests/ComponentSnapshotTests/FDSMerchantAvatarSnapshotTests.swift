import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSMerchantAvatarSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_avatar_initial_fallback() {
        let view = FDSMerchantAvatar(name: "Whole Foods Market", size: 36)
        verifyFDSComponent(view, size: CGSize(width: 120, height: 80))
    }

    func test_avatar_with_symbol() {
        let view = FDSMerchantAvatar(name: "Starbucks", symbol: "cup.and.saucer.fill", size: 36)
        verifyFDSComponent(view, size: CGSize(width: 120, height: 80))
    }

    func test_avatar_small() {
        let view = FDSMerchantAvatar(name: "Target", symbol: "bag.fill", avatarSize: .small)
        verifyFDSComponent(view, size: CGSize(width: 120, height: 80))
    }

    func test_avatar_medium() {
        let view = FDSMerchantAvatar(name: "Amazon", symbol: "shippingbox.fill", avatarSize: .medium)
        verifyFDSComponent(view, size: CGSize(width: 120, height: 80))
    }

    func test_avatar_large() {
        let view = FDSMerchantAvatar(name: "Shell", symbol: "fuelpump.fill", avatarSize: .large)
        verifyFDSComponent(view, size: CGSize(width: 120, height: 100))
    }

    func test_avatar_hero() {
        let view = FDSMerchantAvatar(name: "Salary", symbol: "arrow.down.left.circle.fill", avatarSize: .hero)
        verifyFDSComponent(view, size: CGSize(width: 140, height: 120))
    }

    func test_avatar_deterministic_tints() {
        let view = HStack(spacing: 8) {
            FDSMerchantAvatar(name: "Apple", size: 36)
            FDSMerchantAvatar(name: "Google", size: 36)
            FDSMerchantAvatar(name: "Netflix", size: 36)
            FDSMerchantAvatar(name: "Spotify", size: 36)
        }
        verifyFDSComponent(view, size: CGSize(width: 360, height: 80))
    }
}
