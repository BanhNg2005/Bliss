import SwiftUI
import CoreData

struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Header
            HStack {
                Text("@\(post.wrappedAuthorId)")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Label(post.mediaTypeValue.title, systemImage: post.mediaTypeValue.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Media
            mediaView

            // MARK: - Caption
            if !post.wrappedCaption.isEmpty {
                Text(post.wrappedCaption)
                    .font(.body)
            }

            // MARK: - Footer
            HStack(spacing: 12) {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(post.isLiked ? .pink : .secondary)

                Text("\(post.likeCount) likes")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(post.wrappedCreatedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Media view

    @ViewBuilder
    private var mediaView: some View {
        let urlString = post.wrappedMediaURL

        if urlString.isEmpty {
            // No media attached
            emptyMediaPlaceholder
        } else if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    // Loading
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray.opacity(0.15))
                            .frame(height: 280)
                        ProgressView()
                    }

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                case .failure:
                    // Failed to load
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray.opacity(0.15))
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
            .frame(height: 220)
            .overlay(
                Text("No media")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            )
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let post = Post(context: context)
    post.authorId  = "user_1234"
    post.caption   = "A quiet morning in the city."
    post.createdAt = Date()
    post.lastUpdated = Date()
    post.postId    = UUID().uuidString
    post.mediaType = MediaType.image.rawValue
    post.mediaURL  = "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800"
    post.isLiked   = true
    post.likeCount = 128

    return PostCardView(post: post)
        .padding()
}
