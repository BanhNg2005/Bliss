//
//  FirestoreUser.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-07.
//


import Foundation

struct FirestoreUser: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let username : String
    let email: String  
    let avatarURL: String
    let createdAt: Date
    var isOnline: Bool
    var lastSeen: Date
}
