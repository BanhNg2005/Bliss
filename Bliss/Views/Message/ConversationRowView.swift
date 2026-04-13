import SwiftUI

struct ConversationRowView: View {
    let conversation: FirestoreConversation
    let currentUserId: String

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                url: conversation.otherAvatarURL.isEmpty ? nil : conversation.otherAvatarURL,
                username: conversation.otherUsername.isEmpty ? "?" : conversation.otherUsername,
                size: 48,
                isOnline: conversation.isOtherOnline
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUsername.isEmpty ? "User" : conversation.otherUsername)
                    .font(.subheadline.weight(.semibold))

                Text(conversation.lastMessageText.isEmpty ? "No messages yet" : conversation.lastMessageText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(conversation.lastMessageAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
