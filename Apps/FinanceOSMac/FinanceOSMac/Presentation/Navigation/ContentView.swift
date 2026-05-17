import FinanceCore
import SwiftUI

struct ContentView: View {
    @State private var navigator = AppNavigator()
    private let appContainer = AppContainer.shared

    var body: some View {
        Group {
            #if os(macOS)
            NavigationSplitView(columnVisibility: .constant(.all)) {
                SidebarView()
            } detail: {
                DetailRouter(appContainer: appContainer)
            }
            .navigationSplitViewStyle(.balanced)
            #else
            AdaptiveNavigation()
            #endif
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
