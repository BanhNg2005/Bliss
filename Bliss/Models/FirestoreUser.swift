//
//  FirestoreUser.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-07.
//


import Foundation

struct FirestoreUser: Codable {
    let userId: String
    let username : String
    let avatarURL: String
    let createdAt: Date 
}