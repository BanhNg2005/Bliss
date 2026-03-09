import SwiftUI
import CoreData

struct ChatView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let conversation: Conversation
    let currentUserId: String

    @FetchRequest private var messages: FetchedResults<Message>

    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil

    private let accent = Color(red: 0.78, green: 0.09, blue: 0.2)

    init(conversation: Conversation, currentUserId: String) {
        self.conversation = conversation
        self.currentUserId = currentUserId

        _messages = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
            predicate: NSPredicate(format: "conversation == %@", conversation),
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubbleView(
                                message: message,
                                isFromCurrentUser: message.senderId == currentUserId
                            )
                            .id(message.objectID)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom(proxy: proxy, animated: false)
                    markAsRead()
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 12) {
                TextField("Message...", text: $messageText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : accent)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(.easeInOut(duration: 0.15), value: messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.conversationId ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let message = Message(context: viewContext)
        message.messageId = UUID().uuidString
        message.senderId = currentUserId
        message.text = trimmed
        message.timestamp = Date()
        message.status = false
        message.conversation = conversation

        conversation.lastMessageText = trimmed
        conversation.lastMessageAt = Date()

        messageText = ""

        try? viewContext.save()
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let last = messages.last else { return }
        if animated {
            withAnimation {
                proxy.scrollTo(last.objectID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(last.objectID, anchor: .bottom)
        }
    }

    private func markAsRead() {
        conversation.unreadCount = 0
        try? viewContext.save()
    }
}