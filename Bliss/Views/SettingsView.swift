import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Marketplace") {
                    MarketplaceView()
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
    SettingsView()
}
