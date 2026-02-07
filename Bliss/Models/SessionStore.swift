import Foundation
import Combine

final class SessionStore: ObservableObject {
    @Published private(set) var sessionToken: String
    @Published private(set) var userId: String

    private let tokenKey = "sessionToken"
    private let userIdKey = "sessionUserId"

    var isLoggedIn: Bool {
        !sessionToken.isEmpty
    }

    init() {
        sessionToken = UserDefaults.standard.string(forKey: tokenKey) ?? ""
        userId = UserDefaults.standard.string(forKey: userIdKey) ?? ""
    }

    func startSession(userId: String) {
        let token = UUID().uuidString
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(userId, forKey: userIdKey)
        sessionToken = token
        self.userId = userId
    }

    func endSession() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        sessionToken = ""
        userId = ""
    }
}
