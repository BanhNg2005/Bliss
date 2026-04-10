import SwiftUI
import FirebaseFirestore
import CoreData

struct UserProfileView: View {
    let userId: String
    let currentUserId: String

    @StateObject private var followService = FollowService()
    @StateObject private var postService = PostService()

    @State private var user: FirestoreUser?
    @State private var isLoadingUser = true
    @State private var isFollowLoading = false

    @FetchRequest private var theirPosts: FetchedResults<Post>

    init(userId: String, currentUserId: String) {
        self.userId = userId
        self.currentUserId = currentUserId

        let predicate = NSPredicate(format: "authorId == %@", userId)
        _theirPosts = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Post.createdAt, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }

    private var isFollowing: Bool {
        followService.isFollowing(currentUserId: currentUserId, targetUserId: userId)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                postGrid
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle(user.map { "@\($0.username)" } ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchUser()
            followService.startListening(for: currentUserId)
            postService.startListening(userId: currentUserId)
        }
        .onDisappear {
            followService.stopListening()
            postService.stopListening()
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 84))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            if isLoadingUser {
                ProgressView()
                    .frame(height: 28)
            } else {
                VStack(spacing: 4) {
                    Text("@\(user?.username ?? "unknown")")
                        .font(.title2.weight(.semibold))

                    // Online indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(user?.isOnline == true ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(user?.isOnline == true ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Stats row
            HStack(spacing: 32) {
                statItem(title: "Posts",     value: "\(theirPosts.count)")
                statItem(title: "Followers", value: "\(followService.followers.count)")
                statItem(title: "Following", value: "\(followService.following.count)")
            }
            .padding(.top, 4)

            // Follow button (only show if viewing someone else's profile)
            if userId != currentUserId {
                followButton
            }
        }
        .padding(.horizontal, 16)
    }

    private var followButton: some View {
        Button {
            isFollowLoading = true
            followService.toggleFollow(
                currentUserId: currentUserId,
                targetUserId: userId
            )
            // Small delay to let Firestore listener update
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                isFollowLoading = false
            }
        } label: {
            HStack(spacing: 8) {
                if isFollowLoading {
                    ProgressView()
                        .tint(isFollowing ? Color.primary : Color.white)
                }
                Text(isFollowing ? "Following" : "Follow")
                    .fontWeight(.semibold)
                    .frame(width: 120)
                    .padding(.vertical, 10)
            }
        }
        .background(isFollowing ? Color(.systemGray5) : Color.blue)
        .foregroundStyle(isFollowing ? Color.primary : Color.white)
        .clipShape(Capsule())
        .disabled(isFollowLoading)
        .animation(.easeInOut(duration: 0.2), value: isFollowing)
    }

    // MARK: - Posts

    @ViewBuilder
    private var postGrid: some View {
        if theirPosts.isEmpty {
            VStack(spacing: 8) {
                Text("No posts yet")
                    .font(.headline)
                Text("Nothing to show here.")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
        } else {
            LazyVStack(spacing: 20) {
                ForEach(theirPosts) { post in
                    PostCardView(post: post)
                }
            }
            .padding(.horizontal, 16)
        }
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

    // MARK: - Fetch

    private func fetchUser() {
        isLoadingUser = true
        Task {
            user = try? await UserService().fetchUser(userId: userId)
            isLoadingUser = false
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(userId: "user_123", currentUserId: "user_456")
    }
}
