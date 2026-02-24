import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var sessionStore: SessionStore

    @FetchRequest private var posts: FetchedResults<Post>

    init(sessionStore: SessionStore) {
        _sessionStore = ObservedObject(wrappedValue: sessionStore)
        let predicate = NSPredicate(format: "authorId == %@", sessionStore.userId)
        _posts = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Post.createdAt, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }

    private var friendsCount: Int {
        0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader

                    if posts.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(posts) { post in
                                PostCardView(post: post)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Profile")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 84))
                .foregroundStyle(.linearGradient(
                    colors: [.purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text(sessionStore.userId.isEmpty ? "You" : sessionStore.userId)
                .font(.title2.weight(.semibold))

            HStack(spacing: 24) {
                statItem(title: "Friends", value: "\(friendsCount)")
                statItem(title: "Posts", value: "\(posts.count)")
            }
        }
        .padding(.horizontal, 16)
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No posts yet")
                .font(.headline)
            Text("Create your first post to see it here.")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
    }
}

#Preview {
    ProfileView(sessionStore: SessionStore())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
