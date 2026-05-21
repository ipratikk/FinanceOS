import FinanceCore
import FinanceUI
import SwiftUI

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
                #else
                AdaptiveNavigation()
                #endif
            }

            ToastPresenterView(presenter: navigator.toastPresenter)
        }
        .environment(navigator)
        .sheet(item: $navigator.sheet) { route in
            SheetView(route: route, appContainer: appContainer, navigator: navigator)
        }
    }
}

#Preview {
    ContentView()
}
