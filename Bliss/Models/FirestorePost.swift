import Foundation
import FirebaseFirestore

struct FirestorePost: Codable, Identifiable {
    var id: String { postId }
    let postId: String
    let authorId: String
    var caption: String
    let mediaURL: String
    let mediaType: Int16
    var likeCount: Int
    var likedBy: [String]
    let createdAt: Date

    var mediaTypeValue: MediaType {
        MediaType(rawValue: mediaType) ?? .image
    }
}