import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSNetworkLogoSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_network_logo_visa() {
        let view = FDSNetworkLogo(.visa)
        verifyFDSComponent(view, size: CGSize(width: 160, height: 64))
    }

    func test_network_logo_mastercard() {
        let view = FDSNetworkLogo(.mastercard)
        verifyFDSComponent(view, size: CGSize(width: 160, height: 64))
    }

    func test_network_logo_amex() {
        let view = FDSNetworkLogo(.amex)
        verifyFDSComponent(view, size: CGSize(width: 160, height: 64))
    }

    func test_network_logo_rupay() {
        let view = FDSNetworkLogo(.rupay)
        verifyFDSComponent(view, size: CGSize(width: 160, height: 64))
    }

    func test_network_logo_diners() {
        let view = FDSNetworkLogo(.diners)
        verifyFDSComponent(view, size: CGSize(width: 160, height: 64))
    }

    func test_network_logo_all_in_row() {
        let view = HStack(spacing: 16) {
            FDSNetworkLogo(.visa)
            FDSNetworkLogo(.mastercard)
            FDSNetworkLogo(.amex)
            FDSNetworkLogo(.rupay)
            FDSNetworkLogo(.diners)
        }
        verifyFDSComponent(view, size: CGSize(width: 480, height: 72))
    }
}
