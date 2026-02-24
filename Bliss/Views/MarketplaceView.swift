import SwiftUI

struct MarketplaceView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart.fill")
                .font(.system(size: 36))
            Text("Marketplace")
                .font(.title2.weight(.semibold))
            Text("Coming soon.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .navigationTitle("Marketplace")
    }
}

#Preview {
    NavigationStack {
        MarketplaceView()
    }
}
