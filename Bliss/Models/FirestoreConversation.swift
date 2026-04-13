//
//  FirestoreConversation.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-07.
//

import Foundation
struct FirestoreConversation: Codable, Identifiable, Hashable {
    enum ConversationType: String, Codable {
        case direct
        case marketplace
    }

    var id: String { conversationId }
    let conversationId: String
    let participantIds: [String]
    var lastMessageText: String
    var lastMessageAt: Date
    var conversationType: ConversationType = .direct
    var productId: String? = nil
    var productTitle: String? = nil
    var sellerId: String? = nil
    var sellerUsername: String? = nil

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
        case conversationType
        case productId
        case productTitle
        case sellerId
        case sellerUsername
    }

    init(
        conversationId: String,
        participantIds: [String],
        lastMessageText: String,
        lastMessageAt: Date,
        conversationType: ConversationType = .direct,
        productId: String? = nil,
        productTitle: String? = nil,
        sellerId: String? = nil,
        sellerUsername: String? = nil,
        otherUsername: String = "",
        otherUserId: String = "",
        otherAvatarURL: String = "",
        isOtherOnline: Bool = false
    ) {
        self.conversationId = conversationId
        self.participantIds = participantIds
        self.lastMessageText = lastMessageText
        self.lastMessageAt = lastMessageAt
        self.conversationType = conversationType
        self.productId = productId
        self.productTitle = productTitle
        self.sellerId = sellerId
        self.sellerUsername = sellerUsername
        self.otherUsername = otherUsername
        self.otherUserId = otherUserId
        self.otherAvatarURL = otherAvatarURL
        self.isOtherOnline = isOtherOnline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        participantIds = try container.decode([String].self, forKey: .participantIds)
        lastMessageText = try container.decodeIfPresent(String.self, forKey: .lastMessageText) ?? ""
        lastMessageAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageAt) ?? Date()
        conversationType = try container.decodeIfPresent(ConversationType.self, forKey: .conversationType) ?? .direct
        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        productTitle = try container.decodeIfPresent(String.self, forKey: .productTitle)
        sellerId = try container.decodeIfPresent(String.self, forKey: .sellerId)
        sellerUsername = try container.decodeIfPresent(String.self, forKey: .sellerUsername)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(participantIds, forKey: .participantIds)
        try container.encode(lastMessageText, forKey: .lastMessageText)
        try container.encode(lastMessageAt, forKey: .lastMessageAt)
        try container.encode(conversationType, forKey: .conversationType)
        try container.encodeIfPresent(productId, forKey: .productId)
        try container.encodeIfPresent(productTitle, forKey: .productTitle)
        try container.encodeIfPresent(sellerId, forKey: .sellerId)
        try container.encodeIfPresent(sellerUsername, forKey: .sellerUsername)
    }

    var displayTitle: String {
        if conversationType == .marketplace {
            let product = productTitle?.isEmpty == false ? productTitle! : "Marketplace"
            let seller = sellerUsername?.isEmpty == false ? sellerUsername! : (otherUsername.isEmpty ? "Seller" : otherUsername)
            return "\(product) · \(seller)"
        }
        return otherUsername.isEmpty ? "User" : otherUsername
    }

    var displayPreview: String {
        if conversationType == .marketplace {
            let product = productTitle?.isEmpty == false ? productTitle! : "Marketplace"
            let seller = sellerUsername?.isEmpty == false ? sellerUsername! : (otherUsername.isEmpty ? "Seller" : otherUsername)
            let message = lastMessageText.isEmpty ? "New marketplace message" : lastMessageText
            return "\(product) · \(seller) — \(message)"
        }
        return lastMessageText.isEmpty ? "No messages yet" : lastMessageText
    }
}
