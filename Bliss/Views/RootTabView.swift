import SwiftUI
import UIKit
import CoreData

struct RootTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        _sessionStore = ObservedObject(wrappedValue: sessionStore)
        configureTabBarAppearance()
    }

    var body: some View {
        TabView {
            HomeView(sessionStore: sessionStore)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            DMView()
                .tabItem {
                    Label("DM", systemImage: "paperplane.fill")
                }

            ProfileView(sessionStore: sessionStore)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
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
