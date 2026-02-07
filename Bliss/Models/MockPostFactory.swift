import Foundation
import CoreData
import Combine

struct MockPostFactory {
    static func makePosts(count: Int, in context: NSManagedObjectContext) {
        let captions = [
            "Golden hour vibes.",
            "Weekend reset.",
            "A little joy goes far.",
            "Stillness in the city.",
            "New drop, same energy.",
            "Sunsets and soft light.",
            "Everyday bliss.",
            "Slow down and breathe.",
            "Caught the moment.",
            "Mood: cozy."
        ]

        let mediaURLs = [
            "https://example.com/media/1",
            "https://example.com/media/2",
            "https://www.tiktok.com/@mxtxti?_r=1&_t=ZS-93jZY62tAsi",
            "https://example.com/media/4",
            "https://example.com/media/5"
        ]

        for _ in 0..<count {
            let post = Post(context: context)
            post.postId = UUID().uuidString
            post.authorId = "user_\(Int.random(in: 1000...9999))"
            post.caption = captions.randomElement() ?? "New post."
            post.createdAt = Date().addingTimeInterval(-Double(Int.random(in: 0...86_400)))
            post.lastUpdated = Date()
            post.isLiked = Bool.random()
            post.likeCount = Int32(Int.random(in: 0...5000))
            post.mediaType = Int16(Int.random(in: 0...2))
            post.mediaURL = mediaURLs.randomElement() ?? ""
        }
    }
}
