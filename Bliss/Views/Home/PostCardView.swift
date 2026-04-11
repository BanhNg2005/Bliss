import SwiftUI

struct PostCardView: View {
    let post: FirestorePost
    let currentUserId: String
    let postService: PostService

    @State private var navigateToProfile = false
    @State private var authorUsername: String = ""

    private var isLiked: Bool {
        post.likedBy.contains(currentUserId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Header (tappable author)
            HStack {
                Button {
                    navigateToProfile = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.gray.opacity(0.5))

                        Text(authorUsername.isEmpty ? "Loading..." : "@\(authorUsername)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
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
            }
        }
    }

    // MARK: - Media view

    @ViewBuilder
    private var mediaView: some View {
        if post.mediaURL.isEmpty {
            emptyMediaPlaceholder
        } else if let url = URL(string: post.mediaURL) {
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
                        .scaledToFit()           // scaledToFit keeps image within bounds
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
