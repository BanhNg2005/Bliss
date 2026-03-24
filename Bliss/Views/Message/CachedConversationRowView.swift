import SwiftUI
import CoreData

struct CachedConversationRowView: View {
    let conversation: Conversation       // Core Data
    let enriched: FirestoreConversation? // Live Firestore (for online status)

    var displayName: String {
        enriched?.otherUsername ?? conversation.lastMessageText ?? "User"
    }

    var isOnline: Bool {
        enriched?.isOtherOnline ?? false
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.gray.opacity(0.4))

                if isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(enriched?.otherUsername ?? "User")
                    .font(.subheadline.weight(.semibold))

                Text(conversation.lastMessageText?.isEmpty == false
                     ? conversation.lastMessageText!
                     : "No messages yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let date = conversation.lastMessageAt {
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}