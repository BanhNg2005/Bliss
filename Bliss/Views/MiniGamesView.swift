import SwiftUI

struct MiniGamesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 36))
            Text("Mini Games")
                .font(.title2.weight(.semibold))
            Text("Coming soon.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .navigationTitle("Mini Games")
    }
}

#Preview {
    NavigationStack {
        MiniGamesView()
    }
}
