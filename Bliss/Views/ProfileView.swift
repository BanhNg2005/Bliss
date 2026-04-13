import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @ObservedObject private var sessionStore: SessionStore
    @StateObject private var postService = PostService()
    @StateObject private var followService = FollowService()

    @State private var currentUser: FirestoreUser?
    @State private var isLoadingUser = true
    @State private var avatarURL: String?
    @State private var showFollowers = false
    @State private var showFollowing = false

    init(sessionStore: SessionStore) {
        _sessionStore = ObservedObject(wrappedValue: sessionStore)
    }

    private var myPosts: [FirestorePost] {
        postService.posts.filter { $0.authorId == sessionStore.userId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader

                    if myPosts.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(myPosts) { post in
                                PostCardView(
                                    post: post,
                                    currentUserId: sessionStore.userId,
                                    postService: postService
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Profile")
            .onAppear {
                postService.startListening(userId: sessionStore.userId)
                followService.startListening(for: sessionStore.userId)
                fetchCurrentUser()
            }
            .onDisappear {
                postService.stopListening()
                followService.stopListening()
            }
            .sheet(isPresented: $showFollowers) {
                FollowListView(
                    title: "Followers",
                    userIds: followService.followers,
                    currentUserId: sessionStore.userId
                )
            }
            .sheet(isPresented: $showFollowing) {
                FollowListView(
                    title: "Following",
                    userIds: followService.following,
                    currentUserId: sessionStore.userId
                )
            }
        }
    }

    // MARK: - Profile header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Tappable avatar with camera badge
            AvatarPickerView(
                userId: sessionStore.userId,
                avatarURL: $avatarURL
            )

            if isLoadingUser {
                ProgressView().frame(height: 28)
            } else {
                VStack(spacing: 4) {
                    Text("@\(currentUser?.username ?? "unknown")")
                        .font(.title2.weight(.semibold))

                    if let email = currentUser?.email, !email.isEmpty {
                        Text(email)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Stats row
            HStack(spacing: 32) {
                statItem(title: "Posts", value: "\(myPosts.count)")

                Button { showFollowers = true } label: {
                    statItem(title: "Followers", value: "\(followService.followers.count)")
                }
                .buttonStyle(.plain)

                Button { showFollowing = true } label: {
                    statItem(title: "Following", value: "\(followService.following.count)")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(title).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No posts yet").font(.headline)
            Text("Create your first post to see it here.")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
    }

    private func fetchCurrentUser() {
        isLoadingUser = true
        Task {
            if let user = try? await UserService().fetchUser(userId: sessionStore.userId) {
                currentUser = user
                avatarURL = user.avatarURL.isEmpty ? nil : user.avatarURL
            }
            isLoadingUser = false
        }
    }
}

// MARK: - FollowListView

struct FollowListView: View {
    let title: String
    let userIds: [String]
    let currentUserId: String

    @State private var users: [FirestoreUser] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if users.isEmpty {
                    Text("No \(title.lowercased()) yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(users) { user in
                        NavigationLink {
                            UserProfileView(
                                userId: user.userId,
                                currentUserId: currentUserId
                            )
                        } label: {
                            HStack(spacing: 12) {
                                // Show their avatar if available
                                Group {
                                    if let url = URL(string: user.avatarURL), !user.avatarURL.isEmpty {
                                        AsyncImage(url: url) { phase in
                                            if case .success(let image) = phase {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Image(systemName: "person.crop.circle.fill")
                                                    .font(.system(size: 36))
                                                    .foregroundStyle(.gray.opacity(0.4))
                                            }
                                        }
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundStyle(.gray.opacity(0.4))
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("@\(user.username)")
                                        .font(.subheadline.weight(.semibold))
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(user.isOnline ? Color.green : Color.gray)
                                            .frame(width: 7, height: 7)
                                        Text(user.isOnline ? "Online" : "Offline")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await fetchUsers() }
        }
    }

    private func fetchUsers() async {
        isLoading = true
        var fetched: [FirestoreUser] = []
        for userId in userIds {
            guard !userId.isEmpty else { continue }
            if let user = try? await UserService().fetchUser(userId: userId) {
                fetched.append(user)
            }
        }
        users = fetched
        isLoading = false
    }
}

#Preview {
    ProfileView(sessionStore: SessionStore())
}
