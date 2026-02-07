import SwiftUI
import CoreData
struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("@\(post.wrappedAuthorId)")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Label(post.mediaTypeValue.title, systemImage: post.mediaTypeValue.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(.gray.opacity(0.2))
                .frame(height: 220)
                .overlay(
                    Text("Media preview")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                )

            Text(post.wrappedCaption)
                .font(.body)

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
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let post = Post(context: context)
    post.authorId = "user_1234"
    post.caption = "A quiet morning in the city."
    post.createdAt = Date()
    post.lastUpdated = Date()
    post.postId = UUID().uuidString
    post.mediaType = MediaType.image.rawValue
    post.isLiked = true
    post.likeCount = 128

    return PostCardView(post: post)
}
