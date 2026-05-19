import Foundation
import Observation
import SwiftUI

enum ToastPosition {
    case top
    case bottom
}

enum ToastType {
    case success
    case error
    case warning
    case info
}

struct ToastConfig {
    let message: String
    let type: ToastType
    let position: ToastPosition
    let fullWidth: Bool
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let duration: TimeInterval

    init(
        message: String,
        type: ToastType = .info,
        position: ToastPosition = .top,
        fullWidth: Bool = false,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        duration: TimeInterval = 3.0
    ) {
        self.message = message
        self.type = type
        self.position = position
        self.fullWidth = fullWidth
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.duration = duration
    }
}

@MainActor
@Observable
final class ToastPresenter {
    var currentToast: ToastConfig?
    private var dismissTask: Task<Void, Never>?

    func show(_ config: ToastConfig) {
        dismissTask?.cancel()
        currentToast = config
        scheduleDismissal(after: config.duration)
    }

    func show(
        message: String,
        type: ToastType = .info,
        position: ToastPosition = .top,
        fullWidth: Bool = false,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        duration: TimeInterval = 3.0
    ) {
        let config = ToastConfig(
            message: message,
            type: type,
            position: position,
            fullWidth: fullWidth,
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            duration: duration
        )
        show(config)
    }

    func dismiss() {
        dismissTask?.cancel()
        currentToast = nil
    }

    private func scheduleDismissal(after duration: TimeInterval) {
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                currentToast = nil
            }
        }
    }
}
