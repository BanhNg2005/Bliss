// Models/FirestoreMessage.swift
import Foundation

struct FirestoreMessage: Codable, Identifiable {
    var id: String { messageId }
    let messageId: String
    let conversationId: String
    let senderId: String
    var text: String?
    var mediaURL: String?
    let timestamp: Date
    var isRead: Bool
}