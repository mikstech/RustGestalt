import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        MainTabView()
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.theme) private var theme

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { TweakLibraryView() }
                .tabItem { Label("Library", systemImage: "square.grid.2x2.fill") }

            NavigationStack { IconLibraryView() }
                .tabItem { Label("Icons", systemImage: "app.dashed") }

            NavigationStack { CreatorStudioView() }
                .tabItem { Label("Studio", systemImage: "clapperboard.fill") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }

            if !appState.isPaired {
                NavigationStack { PairingView() }
                    .tabItem { Label("Pair Mac", systemImage: "qrcode") }
            }
        }
        .tint(theme.accent)
    }
}
