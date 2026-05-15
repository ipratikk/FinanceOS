import FinanceCore
import SwiftUI

struct ContentView: View {
    @State private var selection: NavigationItem? = .dashboard
    private let appContainer = AppContainer.shared

    var body: some View {
        #if os(macOS)
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selection: $selection)
        } detail: {
            DetailRouter(selection: selection, appContainer: appContainer)
        }
        .navigationSplitViewStyle(.balanced)
        #else
        AdaptiveNavigation(selection: $selection)
        #endif
    }
}

#Preview {
    ContentView()
}
