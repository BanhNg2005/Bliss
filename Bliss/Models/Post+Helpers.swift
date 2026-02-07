import Foundation
import CoreData

extension Post {
    var wrappedCaption: String {
        caption ?? ""
    }

    var wrappedAuthorId: String {
        authorId ?? "unknown"
    }

    var wrappedPostId: String {
        postId ?? ""
    }

    var wrappedMediaURL: String {
        mediaURL ?? ""
    }

    var wrappedCreatedAt: Date {
        createdAt ?? Date()
    }

    var wrappedLastUpdated: Date {
        lastUpdated ?? Date()
    }

    var mediaTypeValue: MediaType {
        MediaType(rawValue: mediaType) ?? .image
    }
}
