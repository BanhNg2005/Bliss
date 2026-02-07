import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)

            Text("No posts yet")
                .font(.title3.bold())

            Text("Loading sample posts for your feed.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ProgressView()
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

#Preview {
    EmptyStateView()
}
