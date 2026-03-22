// Views/DM/ChatView.swift
import SwiftUI
import CallKit

struct ChatView: View {
    let conversation: FirestoreConversation
    @ObservedObject var sessionStore: SessionStore
    @StateObject private var service = ConversationService()
    @State private var callObserver = CXCallObserver()
    @State private var messageText = ""
    @State private var isSending = false
    
    

    var body: some View {
        VStack(spacing: 0) {
            // Online status bar and call
            HStack {
                Circle()
                    .fill(conversation.isOtherOnline ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(conversation.isOtherOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(service.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isFromCurrentUser: message.senderId == sessionStore.userId
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let last = service.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: service.messages.count) { _ in
                    withAnimation {
                        if let last = service.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 12) {
                TextField("Message...", text: $messageText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationTitle(conversation.otherUsername.isEmpty ? "Chat" : conversation.otherUsername)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            service.listenToMessages(in: conversation.conversationId)
            service.markMessagesAsRead(
                conversationId: conversation.conversationId,
                currentUserId: sessionStore.userId
            )
        }
        .onDisappear {
            service.stopListeningToMessages()
        }
    }

    private func send() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isSending = true
        messageText = ""
        Task {
            try? await service.sendMessage(
                conversationId: conversation.conversationId,
                senderId: sessionStore.userId,
                text: text
            )
            isSending = false
        }
    }
}
