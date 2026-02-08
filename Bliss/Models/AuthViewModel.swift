import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
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
        showConfirmPassword = false
    }

    func submit() {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        if isSignUp {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                return
            }
        }

        isLoading = true

        if isSignUp {
            Auth.auth().createUser(withEmail: trimmedEmail, password: password) { [weak self] result, error in
                self?.handleAuthResult(result: result, error: error)
            }
        } else {
            Auth.auth().signIn(withEmail: trimmedEmail, password: password) { [weak self] result, error in
                self?.handleAuthResult(result: result, error: error)
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

        sessionStore.startSession(userId: userId)
        password = ""
        confirmPassword = ""
        showPassword = false
        showConfirmPassword = false
    }
}
