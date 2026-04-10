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
    
    func createProduct(title: String, description: String, price: Double, condition: String, locationName: String, lat: Double, lon: Double, sellerId: String) async throws {
        let product = FirestoreProduct(
            id: UUID().uuidString,
            sellerId: sellerId,
            title: title,
            description: description,
            price: price,
            condition: condition,
            imageURL: "https://via.placeholder.com/300", // Placeholder for actual image upload
            latitude: lat,
            longitude: lon,
            locationName: locationName,
            createdAt: Date()
        )
        try db.collection("products").document(product.id ?? UUID().uuidString).setData(from: product)
    }
}
