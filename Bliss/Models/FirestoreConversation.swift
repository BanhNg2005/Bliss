//
//  FirestoreConversation.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-07.
//

import Foundation
struct FirestoreConversation: Codable, Identifiable {
    var id: String { conversationId }
    let conversationId: String
    let participantIds: [String]
    var lastMessageText: String
    var lastMessageAt: Date
    var otherUsername: String = ""
    var otherUserId: String = ""
    var otherAvatarURL: String = ""
    var isOtherOnline: Bool = false
}
