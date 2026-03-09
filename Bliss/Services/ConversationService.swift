// Services/ConversationService.swift
import FirebaseFirestore
import FirebaseAuth
import Combine

final class ConversationService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var conversations: [FirestoreConversation] = []
    @Published var messages: [FirestoreMessage] = []

    private var conversationListener: ListenerRegistration?
    private var messageListener: ListenerRegistration?

    // MARK: - Conversations

    func listenToConversations(for userId: String) {
        conversationListener?.remove()
        conversationListener = db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self?.conversations = docs.compactMap {
                    try? $0.data(as: FirestoreConversation.self)
                }
            }
    }

    func createConversation(between currentUserId: String, and otherUserId: String) async throws -> String {
        // Check if conversation already exists
        let existing = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: currentUserId)
            .getDocuments()

        for doc in existing.documents {
            if let conv = try? doc.data(as: FirestoreConversation.self),
               conv.participantIds.contains(otherUserId) {
                return conv.conversationId
            }
        }

        // Create new
        let convId = UUID().uuidString
        let conv = FirestoreConversation(
            conversationId: convId,
            participantIds: [currentUserId, otherUserId],
            lastMessageText: "",
            lastMessageAt: Date()
        )
        try db.collection("conversations").document(convId).setData(from: conv)
        return convId
    }

    func stopListeningToConversations() {
        conversationListener?.remove()
    }

    // MARK: - Messages

    func listenToMessages(in conversationId: String) {
        messageListener?.remove()
        messageListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", ascending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self?.messages = docs.compactMap {
                    try? $0.data(as: FirestoreMessage.self)
                }
            }
    }

    func sendMessage(conversationId: String, senderId: String, text: String) async throws {
        let msgId = UUID().uuidString
        let message = FirestoreMessage(
            messageId: msgId,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            mediaURL: nil,
            timestamp: Date(),
            isRead: false
        )
        try db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(msgId)
            .setData(from: message)

        // Update conversation preview
        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessageText": text,
            "lastMessageAt": Date()
        ])
    }

    func markMessagesAsRead(conversationId: String, currentUserId: String) {
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .whereField("isRead", isEqualTo: false)
            .whereField("senderId", isNotEqualTo: currentUserId)
            .getDocuments { snapshot, _ in
                snapshot?.documents.forEach {
                    $0.reference.updateData(["isRead": true])
                }
            }
    }

    func stopListeningToMessages() {
        messageListener?.remove()
    }
}