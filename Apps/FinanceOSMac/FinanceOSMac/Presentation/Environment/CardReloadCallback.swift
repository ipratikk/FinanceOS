import SwiftUI

extension EnvironmentValues {
    @Entry var cardReloadCallback: (() async -> Void)?
}
