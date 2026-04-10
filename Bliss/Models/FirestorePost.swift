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

extension FirestorePost {
    init(from post: Post) {
        self.postId = post.wrappedPostId
        self.authorId = post.wrappedAuthorId
        self.caption = post.wrappedCaption
        self.mediaURL = post.wrappedMediaURL
        self.mediaType = post.mediaType
        self.likeCount = Int(post.likeCount)
        // Core Data might not store full likedBy array, so assume empty if not stored,
        // or just use what we have to satisfy the basic struct shape
        self.likedBy = []
        self.createdAt = post.createdAt ?? Date()
    }
}
