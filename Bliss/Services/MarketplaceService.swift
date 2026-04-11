import SwiftUI
import FirebaseFirestore
import Foundation
import Combine // Added Combine for ObservableObject

@MainActor
class MarketplaceService: ObservableObject {
    @Published var products: [FirestoreProduct] = []
    
    private let db = Firestore.firestore()
    
    func fetchProducts() {
        db.collection("products").order(by: "createdAt", descending: true).addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else { return }
            self.products = docs.compactMap { try? $0.data(as: FirestoreProduct.self) }
        }
    }
    
    // Updated to accept postalCode and optionally base64 image data
    func createProduct(title: String, description: String, price: Double, condition: String, locationName: String, postalCode: String, lat: Double, lon: Double, sellerId: String, imageData: Data?) async throws {
        
        // Convert local image data to base64 if available, otherwise use placeholder fallback
        // Firestore has a 1MB limit so the data must be highly compressed
        let base64String = imageData?.base64EncodedString()
        let finalImageURL = base64String != nil ? "data:image/jpeg;base64,\(base64String!)" : "https://via.placeholder.com/300"

        let product = FirestoreProduct(
            id: UUID().uuidString,
            sellerId: sellerId,
            title: title,
            description: description,
            price: price,
            condition: condition,
            imageURL: finalImageURL,
            latitude: lat,
            longitude: lon,
            locationName: locationName,
            postalCode: postalCode,
            createdAt: Date()
        )
        try db.collection("products").document(product.id ?? UUID().uuidString).setData(from: product)
    }
}
