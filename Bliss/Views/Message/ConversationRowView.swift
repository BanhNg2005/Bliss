// Views/DM/ConversationRowView.swift
import SwiftUI

struct ConversationRowView: View {
    let conversation: FirestoreConversation
    let currentUserId: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.gray.opacity(0.4))

                if conversation.isOtherOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                }
            }

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
