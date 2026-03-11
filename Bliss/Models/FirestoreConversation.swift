//
//  FirestoreConversation.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-07.
//

import Foundation
struct FirestoreConversation: Codable, Identifiable, Hashable {
    var id: String { conversationId }
    let conversationId: String
    let participantIds: [String]
    var lastMessageText: String
    var lastMessageAt: Date

    // Client-side only — not stored in Firestore
    var otherUsername: String = ""
    var otherUserId: String = ""
    var otherAvatarURL: String = ""
    var isOtherOnline: Bool = false

    enum CodingKeys: String, CodingKey {
        case conversationId
        case participantIds
        case lastMessageText
        case lastMessageAt
    }
}
