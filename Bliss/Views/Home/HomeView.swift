import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var sessionStore: SessionStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Post.createdAt, ascending: false)],
        animation: .default)
    private var posts: FetchedResults<Post>

    @State private var showCreatePost = false
    @State private var didSeed = false

    private var randomizedPosts: [Post] {
        posts.shuffled()
    }

    var body: some View {
        NavigationStack {
            Group {
                if posts.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(randomizedPosts) { post in
                                PostCardView(post: post)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Bliss")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showCreatePost = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }

                        Button {
                            sessionStore.endSession()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        .accessibilityLabel("Sign Out")
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(authorId: sessionStore.userId)
                    .environment(\.managedObjectContext, viewContext)
            }
            .task {
                guard !didSeed else { return }
                didSeed = true
                PostSeeder.seedIfNeeded(in: viewContext)
            }
        }
    }
}

#Preview {
    HomeView(sessionStore: SessionStore())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
