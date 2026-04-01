//
//  UserService.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-07.
//


import FirebaseFirestore

final class UserService {
    private let db = Firestore.firestore()

    func createUser(_ user: FirestoreUser) async throws {
        try db.collection("users")
            .document(user.userId)
            .setData(from: user)
    }

    func fetchUser(userId: String) async throws -> FirestoreUser {
        try await db.collection("users")
            .document(userId)
            .getDocument(as: FirestoreUser.self)
    }

    func searchUsers(username: String) async throws -> [FirestoreUser] {
        let snapshot = try await db.collection("users")
            .getDocuments()
        
        return snapshot.documents
            .compactMap { try? $0.data(as: FirestoreUser.self) }
            .filter { $0.username.lowercased().contains(username.lowercased()) }
            .filter { $0.userId != "" }
    }

    func setOnlineStatus(userId: String, isOnline: Bool) {
        guard !userId.isEmpty else { return }
        db.collection("users").document(userId).updateData([
            "isOnline": isOnline,
            "lastSeen": Date()
        ])
    }
    
    func updateUserOnlineStatus(userId: String, isOnline: Bool) {
        guard !userId.isEmpty else { return }
        db.collection("users").document(userId).updateData([
            "isOnline": isOnline,
            "lastSeen": Date()
        ])
    }
}
