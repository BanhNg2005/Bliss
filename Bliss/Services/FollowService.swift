import FirebaseFirestore
import Combine

@MainActor
final class FollowService: ObservableObject {
    @Published var followers: [String] = []  // userIds following this profile
    @Published var following: [String] = []  // userIds this profile follows

    private let db = Firestore.firestore()
    private var followersListener: ListenerRegistration?
    private var followingListener: ListenerRegistration?

    // MARK: - Listen to follow counts for a profile

    func startListening(for userId: String) {
        // Who follows this user
        followersListener?.remove()
        followersListener = db.collection("follows")
            .whereField("followingId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.followers = snapshot?.documents.compactMap {
                    $0.data()["followerId"] as? String
                } ?? []
            }

        // Who this user follows
        followingListener?.remove()
        followingListener = db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.following = snapshot?.documents.compactMap {
                    $0.data()["followingId"] as? String
                } ?? []
            }
    }

    func stopListening() {
        followersListener?.remove()
        followingListener?.remove()
    }

    // MARK: - Check if currentUser follows targetUser

    func isFollowing(currentUserId: String, targetUserId: String) -> Bool {
        following.contains(targetUserId)
    }

    // MARK: - Follow

    func follow(currentUserId: String, targetUserId: String) async throws {
        let docId = "\(currentUserId)_\(targetUserId)"
        try await db.collection("follows").document(docId).setData([
            "followerId":  currentUserId,
            "followingId": targetUserId,
            "createdAt":   Date()
        ])
    }

    // MARK: - Unfollow

    func unfollow(currentUserId: String, targetUserId: String) async throws {
        let docId = "\(currentUserId)_\(targetUserId)"
        try await db.collection("follows").document(docId).delete()
    }

    // MARK: - Toggle

    func toggleFollow(currentUserId: String, targetUserId: String) {
        Task {
            do {
                if isFollowing(currentUserId: currentUserId, targetUserId: targetUserId) {
                    try await unfollow(currentUserId: currentUserId, targetUserId: targetUserId)
                } else {
                    try await follow(currentUserId: currentUserId, targetUserId: targetUserId)
                }
            } catch {
                print("FollowService error: \(error.localizedDescription)")
            }
        }
    }
}