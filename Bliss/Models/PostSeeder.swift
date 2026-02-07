import CoreData

struct PostSeeder {
    static func seedIfNeeded(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Post> = Post.fetchRequest()
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            guard count == 0 else { return }

            MockPostFactory.makePosts(count: 12, in: context)
            try context.save()
        } catch {
            // Keep seeding failures silent to avoid blocking the UI.
        }
    }
}
