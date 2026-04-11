import SwiftUI

struct SettingsView: View {
    @ObservedObject var sessionStore: SessionStore
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Marketplace") {
                    MarketplaceView(sessionStore: sessionStore)
                }
                NavigationLink("Mini Games") {
                    MiniGamesView()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView(sessionStore: SessionStore())
}
