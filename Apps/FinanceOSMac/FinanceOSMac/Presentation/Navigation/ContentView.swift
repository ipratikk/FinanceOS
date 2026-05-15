import SwiftUI

struct ContentView: View {
    @State private var selection: NavigationItem? = .dashboard

    var body: some View {
        #if os(macOS)
        NavigationSplitView(columnVisibility: .all) {
            SidebarView(selection: $selection)
        } detail: {
            DetailRouter(selection: selection)
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
