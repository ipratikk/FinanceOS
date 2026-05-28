import FinanceCore
import FinanceUI
import SwiftUI

#if os(macOS)
private class _BackgroundNSView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.backgroundColor = NSColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1.0)
    }
}

private struct WindowBackgroundSetter: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        _BackgroundNSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif

struct ContentView: View {
    @State private var navigator = AppNavigator()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    private let appContainer = AppContainer.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            Wallpaper()

            Group {
                #if os(macOS)
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SidebarView()
                } detail: {
                    DetailRouter(appContainer: appContainer)
                }
                .navigationSplitViewStyle(.balanced)
                .background(WindowBackgroundSetter())
                .toolbar(removing: .sidebarToggle)
                .toolbarBackground(.hidden, for: .windowToolbar)
                #else
                AdaptiveNavigation()
                #endif
            }

            ToastPresenterView(presenter: navigator.toastPresenter)
        }
        .environment(navigator)
        .sheet(item: $navigator.sheet) { route in
            SheetView(route: route, appContainer: appContainer, navigator: navigator)
                .glassEffect()
        }
    }
}

#Preview {
    ContentView()
}
