import SwiftUI
import UIKit
import CoreData

struct RootTabView: View {
    enum Tab: Hashable {
        case home
        case dm
        case profile
        case settings
    }

    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var sessionStore: SessionStore
    @State private var selectedTab: Tab = .home
    @State private var showMiniGames = false
    @State private var urlObserver: NSObjectProtocol?

    init(sessionStore: SessionStore) {
        _sessionStore = ObservedObject(wrappedValue: sessionStore)
        configureTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(sessionStore: sessionStore)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            DMView(sessionStore: sessionStore)
                .tabItem {
                    Label("DM", systemImage: "paperplane.fill")
                }
                .tag(Tab.dm)

            ProfileView(sessionStore: sessionStore)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)

            SettingsView(sessionStore: sessionStore)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .sheet(isPresented: $showMiniGames) {
            NavigationStack {
                MiniGamesView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("bliss.openURL"))) { notification in
            if let url = notification.object as? URL {
                handleDeepLink(url)
            }
        }
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "bliss" else { return }
        if url.host == "minigames" || url.path == "/minigames" {
            selectedTab = .home
            showMiniGames = true
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.clear
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView(sessionStore: SessionStore())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
