import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        let accent = Color(red: 0.78, green: 0.09, blue: 0.2)

        return ZStack {
            LinearGradient(
                colors: [accent.opacity(0.95), accent.opacity(0.7), accent.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bliss")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)

                        Text(viewModel.isSignUp ? "Create Your Account" : "Welcome Back")
                            .foregroundStyle(.white.opacity(0.85))
                            .font(.title3.weight(.semibold))
                    }

                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(viewModel.isSignUp ? .newPassword : .password)
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        if viewModel.isSignUp {
                            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .foregroundStyle(.white)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                    }

                    Button(action: viewModel.submit) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                            }
                            Text(viewModel.isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(accent)
                    .disabled(viewModel.isLoading)

                    Button(action: viewModel.toggleMode) {
                        Text(viewModel.isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(sessionStore: SessionStore()))
}
