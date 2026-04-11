import Foundation
import FirebaseFirestore
import CoreLocation

struct FirestoreProduct: Codable, Identifiable {
    @DocumentID var id: String?
    var sellerId: String
    var title: String
    var description: String
    var price: Double
    var condition: String
    var imageURL: String
    var latitude: Double
    var longitude: Double
    var locationName: String // Keep for backwards compatibility
    var postalCode: String? // Optional for backwards compatibility
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
