//
//  FirebaseFirestore.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-07.
//

import Foundation
import FirebaseFirestore
final class UserService{
    private let db = Firestore.firestore();
    
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
}
