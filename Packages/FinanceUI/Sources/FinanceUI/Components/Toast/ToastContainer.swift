import FinanceCore
import SwiftUI

public struct ToastContainer: View {
    @State private var toasts: [Toast] = []

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(toasts) { toast in
                ToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        scheduleRemoval(of: toast)
                    }
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func scheduleRemoval(of toast: Toast) {
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            withAnimation(.easeInOut(duration: 0.2)) {
                toasts.removeAll { $0.id == toast.id }
            }
        }
    }

    public func show(_ toast: Toast) {
        withAnimation(.easeInOut(duration: 0.2)) {
            toasts.append(toast)
        }
    }
}

public class ToastManager: ObservableObject {
    @Published var toasts: [Toast] = []

    public static let shared = ToastManager()

    public func show(
        message: String,
        type: Toast.ToastType = .info,
        duration: TimeInterval = 4.0
    ) {
        let toast = Toast(message: message, type: type, duration: duration)
        show(toast)
    }

    public func show(_ toast: Toast) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.toasts.append(toast)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.toasts.removeAll { $0.id == toast.id }
                }
            }
        }
    }
}

public struct ToastContainerView: View {
    @StateObject private var manager = ToastManager.shared

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(manager.toasts) { toast in
                ToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ZStack {
        AppColors.base
            .ignoresSafeArea()

        ToastContainerView()
    }
    .onAppear {
        ToastManager.shared.show(message: "Import successful", type: .success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ToastManager.shared.show(message: "Warning: Check your data", type: .warning)
        }
    }
}
