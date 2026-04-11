import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var sessionStore: SessionStore
    @StateObject private var postService = PostService()

    @State private var showCreatePost = false

    var body: some View {
        NavigationStack {
            ZStack {
                if postService.posts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        if postService.isOffline {
                            HStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .font(.caption)
                                Text("You're offline — showing cached posts")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .clipShape(Capsule())
                            .padding(.top, 8)
                        }

                        LazyVStack(spacing: 20) {
                            ForEach(postService.posts) { post in
                                PostCardView(
                                    post: post,
                                    currentUserId: sessionStore.userId,
                                    postService: postService
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Bliss")
            .toolbar {
                // This places the button on the far left
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }

                // This places the button on the far right
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sessionStore.endSession()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Sign Out")
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(authorId: sessionStore.userId)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                postService.startListening(userId: sessionStore.userId)
            }
            .onDisappear {
                postService.stopListening()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("No posts yet")
                .font(.title3.bold())
            Text("Be the first to post something!")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView(sessionStore: SessionStore())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
