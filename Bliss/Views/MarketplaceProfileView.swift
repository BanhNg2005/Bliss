import SwiftUI
import CoreLocation

struct MarketplaceProfileView: View {
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var service: MarketplaceService
    let userLocation: CLLocation
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("savedMarketplaceProductIds") private var savedProductIdsData: Data = Data()
    
    var savedProductIds: [String] {
        (try? JSONDecoder().decode([String].self, from: savedProductIdsData)) ?? []
    }
    
    @State private var selectedTab = 0
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var myProducts: [FirestoreProduct] {
        service.products.filter { $0.sellerId == sessionStore.userId }
    }
    
    var savedProducts: [FirestoreProduct] {
        service.products.filter { savedProductIds.contains($0.id ?? "") }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tabs", selection: $selectedTab) {
                Text("My Listings").tag(0)
                Text("My Interests").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            ScrollView {
                if selectedTab == 0 {
                    if myProducts.isEmpty {
                        emptyState(text: "You haven't listed any products yet.")
                    } else {
                        productGrid(products: myProducts)
                    }
                } else {
                    if savedProducts.isEmpty {
                        emptyState(text: "You haven't saved any products yet.")
                    } else {
                        productGrid(products: savedProducts)
                    }
                }
            }
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func emptyState(text: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text(text)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }
    
    @ViewBuilder
    private func productGrid(products: [FirestoreProduct]) -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(products) { product in
                NavigationLink {
                    ProductDetailView(product: product, userLocation: userLocation, sessionStore: sessionStore)
                } label: {
                    ProductCard(product: product, userLocation: userLocation)
                }
            }
        }
        .padding()
    }
}
