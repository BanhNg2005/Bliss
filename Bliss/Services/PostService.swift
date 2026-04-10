import FirebaseFirestore
import CoreData
import Network
import Combine

@MainActor
final class PostService: ObservableObject {
    @Published var posts: [FirestorePost] = []
    @Published var isOffline: Bool = false

    private let db = Firestore.firestore()
    private let context: NSManagedObjectContext
    private var listener: ListenerRegistration?
    private let monitor = NWPathMonitor()
    private var currentUserId: String = ""

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Start listening

    func startListening(userId: String = "") {
        currentUserId = userId

        // 1. Show cached posts immediately so the feed isn't empty on launch
        loadFromCoreData()

        // 2. Monitor network connectivity
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isOffline = path.status != .satisfied
            }
        }
        monitor.start(queue: DispatchQueue(label: "PostService.NetworkMonitor"))

        // 3. Attach Firestore real-time listener
        listener?.remove()
        listener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("PostService Firestore error: \(error.localizedDescription)")
                    // Keep showing cached posts — don't wipe the feed
                    return
                }

                guard let docs = snapshot?.documents else { return }
                let fetched = docs.compactMap { try? $0.data(as: FirestorePost.self) }

                // Update published feed
                self.posts = fetched

                // Persist to Core Data so offline reads work later
                Task {
                    await self.upsertToCoreData(fetched)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        monitor.cancel()
    }

    // MARK: - Like / Unlike

    func toggleLike(post: FirestorePost, userId: String) {
        // Optimistic local update so the UI feels instant
        if let index = posts.firstIndex(where: { $0.postId == post.postId }) {
            if post.likedBy.contains(userId) {
                posts[index].likedBy.removeAll { $0 == userId }
                posts[index].likeCount -= 1
            } else {
                posts[index].likedBy.append(userId)
                posts[index].likeCount += 1
            }
        }

        // Write to Firestore
        let ref = db.collection("posts").document(post.postId)
        if post.likedBy.contains(userId) {
            ref.updateData([
                "likedBy":   FieldValue.arrayRemove([userId]),
                "likeCount": FieldValue.increment(Int64(-1))
            ])
        } else {
            ref.updateData([
                "likedBy":   FieldValue.arrayUnion([userId]),
                "likeCount": FieldValue.increment(Int64(1))
            ])
        }

        // Update Core Data cache for the liked post
        updateLikeInCoreData(postId: post.postId, liked: !post.likedBy.contains(userId))
    }

    // MARK: - Core Data: load cached posts (offline fallback)

    private func loadFromCoreData() {
        let request: NSFetchRequest<Post> = Post.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Post.createdAt, ascending: false)]

        guard let cached = try? context.fetch(request), !cached.isEmpty else { return }

        // Only use cache if Firestore hasn't loaded yet
        if posts.isEmpty {
            posts = cached.map { FirestorePost(from: $0) }
        }
    }

    // MARK: - Core Data: upsert posts from Firestore

    private func upsertToCoreData(_ firestorePosts: [FirestorePost]) async {
        let bgContext = PersistenceController.shared.container.newBackgroundContext()
        bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        await bgContext.perform {
            for fp in firestorePosts {
                let request: NSFetchRequest<Post> = Post.fetchRequest()
                request.predicate = NSPredicate(format: "postId == %@", fp.postId)
                request.fetchLimit = 1

                let post = (try? bgContext.fetch(request))?.first ?? Post(context: bgContext)
                post.postId      = fp.postId
                post.authorId    = fp.authorId
                post.caption     = fp.caption
                post.mediaURL    = fp.mediaURL
                post.mediaType   = fp.mediaType
                post.likeCount   = Int32(fp.likeCount)
                post.isLiked     = fp.likedBy.contains(self.currentUserId)
                post.createdAt   = fp.createdAt
                post.lastUpdated = Date()
            }

            try? bgContext.save()
        }
    }

    // MARK: - Core Data: update like status for a single post

    private func updateLikeInCoreData(postId: String, liked: Bool) {
        let request: NSFetchRequest<Post> = Post.fetchRequest()
        request.predicate = NSPredicate(format: "postId == %@", postId)
        request.fetchLimit = 1

        guard let post = (try? context.fetch(request))?.first else { return }
        post.isLiked = liked
        if liked { post.likeCount += 1 } else { post.likeCount -= 1 }
        try? context.save()
    }
}
