import SwiftUI

struct DMView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 36))
                Text("Direct Messages")
                    .font(.title2.weight(.semibold))
                Text("Messaging is coming soon.")
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .navigationTitle("Messages")
        }
    }
}

#Preview {
    DMView()
}
