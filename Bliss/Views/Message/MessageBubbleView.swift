
import SwiftUI

struct MessageBubbleView: View {
    let message: FirestoreMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if let text = message.text, !text.isEmpty {
                    Text(text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(isFromCurrentUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if isFromCurrentUser {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundStyle(message.isRead ? .blue : .secondary)
                    }
                }
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}
