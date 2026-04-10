import SwiftUI
import CoreLocation
import MapKit

struct ProductDetailView: View {
    let product: FirestoreProduct
    let userLocation: CLLocation
    @Environment(\.dismiss) var dismiss
    
    // For storing interested sellers locally
    @AppStorage("interestedSellerIds") private var interestedSellersData: Data = Data()
    @State private var showMessageAlert = false
    
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: product.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Large Image
                AsyncImage(url: URL(string: product.imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 300)
                .clipped()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(product.title)
                        .font(.title2.bold())
                    
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.title.bold())
                    
                    Text("Condition: \(product.condition)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("Description")
                        .font(.headline)
                    Text(product.description)
                        .font(.body)
                    
                    Divider()
                    
                    Text("Rental Location")
                        .font(.headline.bold())
                    
                    Map(coordinateRegion: .constant(region), annotationItems: [product]) { p in
                        MapMarker(coordinate: p.coordinate, tint: .red)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    
                    Text(product.locationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        markInterest()
                        showMessageAlert = true
                    } label: {
                        Text("Message Seller")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 16)
                    .alert("Message Sent", isPresented: $showMessageAlert) {
                        Button("OK", role: .cancel) { dismiss() }
                    } message: {
                        Text("The seller has been added to your interested list in DMs.")
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func markInterest() {
        var ids = (try? JSONDecoder().decode([String].self, from: interestedSellersData)) ?? []
        if !ids.contains(product.sellerId) {
            ids.append(product.sellerId)
            if let d = try? JSONEncoder().encode(ids) {
                interestedSellersData = d
            }
        }
    }
}
