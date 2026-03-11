//
//  ConversationService.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-07.
//

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
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("Conversation listener error: \(error.localizedDescription)")
                    return
                }

                print("\(snapshot?.documents.count ?? 0) conversations")
                snapshot?.documents.forEach { print("  - \($0.documentID)") }

                guard let docs = snapshot?.documents else { return }
                let raw = docs.compactMap { try? $0.data(as: FirestoreConversation.self) }
                print("\(raw.count) conversations")

                Task {
                    var enriched: [FirestoreConversation] = []
                    for var conv in raw {
                        let otherUserId = conv.participantIds.first { $0 != userId } ?? ""
                        if let otherUser = try? await UserService().fetchUser(userId: otherUserId) {
                            conv.otherUserId = otherUserId
                            conv.otherUsername = otherUser.username
                            conv.otherAvatarURL = otherUser.avatarURL
                            conv.isOtherOnline = otherUser.isOnline
                        }
                        enriched.append(conv)
                    }
                    await MainActor.run {
                        self.conversations = enriched.sorted { $0.lastMessageAt > $1.lastMessageAt }
                    }
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
        try await db.collection("conversations").document(convId).setData([
            "conversationId": convId,
            "participantIds": [currentUserId, otherUserId],
            "lastMessageText": "",
            "lastMessageAt": Date()
        ])
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
            .order(by: "timestamp", descending: false)
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
            .getDocuments { snapshot, _ in
                snapshot?.documents.forEach { doc in
                    let senderId = doc.data()["senderId"] as? String ?? ""
                    let isRead = doc.data()["isRead"] as? Bool ?? true
                    if senderId != currentUserId && !isRead {
                        doc.reference.updateData(["isRead": true])
                    }
                }
            }
    }

    func stopListeningToMessages() {
        messageListener?.remove()
    }
}
