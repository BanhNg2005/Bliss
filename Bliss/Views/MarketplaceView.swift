import SwiftUI
import CoreLocation

struct MarketplaceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = MarketplaceService()
    
    @State private var searchText = ""
    @State private var sortType: SortType = .newest
    @State private var showCreateListing = false
    
    // Simple placeholder user location
    let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // SF
    
    enum SortType: String, CaseIterable {
        case newest = "Newest"
        case price = "Price"
        case condition = "Condition"
        case distance = "Distance"
    }

    var filteredProducts: [FirestoreProduct] {
        var result = service.products
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortType {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .price:
            result.sort { $0.price < $1.price }
        case .condition:
            // Custom simplified sort: New -> Used Like New -> Used Good -> Used Fair
            result.sort { $0.condition > $1.condition }
        case .distance:
            result.sort {
                let loc0 = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                let loc1 = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
                return loc0.distance(from: userLocation) < loc1.distance(from: userLocation)
            }
        }
        return result
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                TextField("Search products...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Menu {
                    Picker("Sort By", selection: $sortType) {
                        ForEach(SortType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                }
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredProducts) { product in
                        NavigationLink {
                            ProductDetailView(product: product, userLocation: userLocation)
                        } label: {
                            ProductCard(product: product, userLocation: userLocation)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear { service.fetchProducts() }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showCreateListing = true }) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .sheet(isPresented: $showCreateListing) {
            CreateListingView(service: service)
        }
    }
}

struct ProductCard: View {
    let product: FirestoreProduct
    let userLocation: CLLocation
    
    var distanceString: String {
        let loc = CLLocation(latitude: product.latitude, longitude: product.longitude)
        let miles = loc.distance(from: userLocation) / 1609.34
        return String(format: "%.1f mi", miles)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(product.title)
                .font(.headline)
                .lineLimit(1)
            
            Text("$\(product.price, specifier: "%.2f")")
                .font(.subheadline.bold())
            
            Text(product.condition)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(product.locationName) • \(distanceString)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4)
        .foregroundColor(.primary)
    }
}

#Preview {
    NavigationStack {
        MarketplaceView()
    }
}
