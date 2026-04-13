import SwiftUI
import AVKit

struct PostCardView: View {
    let post: FirestorePost
    let currentUserId: String
    let postService: PostService

    @State private var navigateToProfile = false
    @State private var authorUsername: String = ""
    @State private var authorAvatarURL: String? = nil

    private var isLiked: Bool {
        post.likedBy.contains(currentUserId)
    }

    private var isVideo: Bool {
        post.mediaTypeValue == .video || post.mediaTypeValue == .reel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Header with real avatar
            HStack(spacing: 10) {
                Button {
                    navigateToProfile = true
                } label: {
                    HStack(spacing: 10) {
                        AvatarView(
                            url: authorAvatarURL,
                            username: authorUsername.isEmpty ? "?" : authorUsername,
                            size: 36
                        )

                        VStack(alignment: .leading, spacing: 1) {
                            Text(authorUsername.isEmpty ? "Loading..." : "@\(authorUsername)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Label(post.mediaTypeValue.title, systemImage: post.mediaTypeValue.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Media
            mediaView

            // MARK: - Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.body)
            }

            // MARK: - Footer
            HStack(spacing: 12) {
                Button {
                    postService.toggleLike(post: post, userId: currentUserId)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? .pink : .secondary)
                            .contentTransition(.symbolEffect(.replace))

                        Text("\(post.likeCount) likes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text(post.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .navigationDestination(isPresented: $navigateToProfile) {
            UserProfileView(
                userId: post.authorId,
                currentUserId: currentUserId
            )
        }
        .task {
            guard !post.authorId.isEmpty else { return }
            if let user = try? await UserService().fetchUser(userId: post.authorId) {
                authorUsername = user.username
                authorAvatarURL = user.avatarURL.isEmpty ? nil : user.avatarURL
            }
        }
    }

    // MARK: - Media view

    @ViewBuilder
    private var mediaView: some View {
        if post.mediaURL.isEmpty {
            emptyMediaPlaceholder
        } else if let url = URL(string: post.mediaURL) {
            if isVideo {
                VideoPlayerView(url: url)
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.gray.opacity(0.15))
                                .frame(maxWidth: .infinity)
                                .frame(height: 280)
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.gray.opacity(0.15))
                                .frame(maxWidth: .infinity)
                                .frame(height: 280)
                            VStack(spacing: 8) {
                                Image(systemName: "photo.slash")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                                Text("Could not load image")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    @unknown default:
                        emptyMediaPlaceholder
                    }
                }
            }
        } else {
            emptyMediaPlaceholder
        }
    }

    private var emptyMediaPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.gray.opacity(0.15))
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .overlay(
                Text("No media")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            )
    }
}
