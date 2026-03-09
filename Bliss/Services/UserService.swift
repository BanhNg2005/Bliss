// Services/UserService.swift
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
            .whereField("username", isGreaterThanOrEqualTo: username)
            .whereField("username", isLessThanOrEqualTo: username + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments()
        return snapshot.documents.compactMap {
            try? $0.data(as: FirestoreUser.self)
        }
    }

    func setOnlineStatus(userId: String, isOnline: Bool) {
        db.collection("users").document(userId).updateData([
            "isOnline": isOnline,
            "lastSeen": Date()
        ])
    }
}