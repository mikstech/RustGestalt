import SwiftUI

@main
struct RustGestaltApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ThemedRoot {
                RootView()
                    .environmentObject(appState)
            }
        }
    }
}
