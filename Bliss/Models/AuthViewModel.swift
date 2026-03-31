import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var emailOrUsername = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    @Published var isSignUp = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPassword = false
    @Published var showConfirmPassword = false

    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func toggleMode() {
        isSignUp.toggle()
        errorMessage = nil
        confirmPassword = ""
        username = ""
        emailOrUsername = ""
        showConfirmPassword = false
    }

    func submit() {
        errorMessage = nil
        let input = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !input.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return
        }

        if isSignUp {
            guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Username is required."
                return
            }
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                return
            }
            isLoading = true
            Auth.auth().createUser(withEmail: input, password: password) { [weak self] result, error in
                self?.handleAuthResult(result: result, error: error)
            }
        } else {
            isLoading = true
            if input.contains("@") {
                signInWithEmail(input)
            } else {
                signInWithUsername(input)
            }
        }
    }

    private func signInWithEmail(_ email: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            self?.handleAuthResult(result: result, error: error)
        }
    }

    private func signInWithUsername(_ username: String) {
        Task {
            do {
                let snapshot = try await Firestore.firestore()
                    .collection("users")
                    .whereField("username", isEqualTo: username)
                    .limit(to: 1)
                    .getDocuments()

                guard let doc = snapshot.documents.first,
                      let email = doc.data()["email"] as? String else {
                    self.errorMessage = "No account found with that username."
                    self.isLoading = false
                    return
                }

                Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
                    self?.handleAuthResult(result: result, error: error)
                }
            } catch {
                self.errorMessage = "Login failed. Try again."
                self.isLoading = false
            }
        }
    }

    private func handleAuthResult(result: AuthDataResult?, error: Error?) {
        isLoading = false

        if let error = error {
            errorMessage = error.localizedDescription
            return
        }

        guard let userId = result?.user.uid else {
            errorMessage = "Unable to start session."
            return
        }

        if isSignUp {
            let user = FirestoreUser(
                userId: userId,
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                email: emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines),
                avatarURL: "",
                createdAt: Date(),
                isOnline: true,
                lastSeen: Date()
            )
            Task {
                try? await UserService().createUser(user)
            }
        }

        sessionStore.startSession(with: FirestoreUser(
            userId: userId,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            email: emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarURL: "",
            createdAt: Date(),
            isOnline: true,
            lastSeen: Date()
        ))
        emailOrUsername = ""
        username = ""
        password = ""
        confirmPassword = ""
        showPassword = false
        showConfirmPassword = false
    }
}
