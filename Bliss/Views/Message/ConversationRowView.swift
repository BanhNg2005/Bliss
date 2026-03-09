import SwiftUI
import CoreData

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 50, height: 50)

                Text(avatarInitial)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.conversationId ?? "Unknown")
                        .font(.subheadline.bold())
                        .lineLimit(1)

                    Spacer()

                    if let date = conversation.lastMessageAt {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text(conversation.lastMessageText ?? "No messages yet")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.78, green: 0.09, blue: 0.2))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var avatarInitial: String {
        String((conversation.conversationId ?? "?").prefix(1)).uppercased()
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal, .indigo]
        let index = abs((conversation.conversationId ?? "").hashValue) % colors.count
        return colors[index]
    }
}