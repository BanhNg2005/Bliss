import Foundation
import Combine

final class SessionStore: ObservableObject {
    @Published private(set) var sessionToken: String
    @Published private(set) var userId: String
    @Published private(set) var username: String

    private let tokenKey = "sessionToken"
    private let userIdKey = "sessionUserId"
    private let usernameKey = "sessionUsername"

    var isLoggedIn: Bool {
        !sessionToken.isEmpty
    }

    init() {
        sessionToken = UserDefaults.standard.string(forKey: tokenKey) ?? ""
        userId = UserDefaults.standard.string(forKey: userIdKey) ?? ""
        username = UserDefaults.standard.string(forKey: usernameKey) ?? ""
    }

    func startSession(with user: FirestoreUser) {
        let token = UUID().uuidString
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(userId, forKey: userIdKey)
        UserDefaults.standard.set(username, forKey: usernameKey)
        UserService().updateUserOnlineStatus(userId: user.userId, isOnline: true)
        sessionToken = token
        self.userId = user.userId
        self.username = user.username
    }

    func endSession() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
        sessionToken = ""
        userId = ""
        username = ""
    }
}
