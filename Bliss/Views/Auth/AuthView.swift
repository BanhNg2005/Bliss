import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showForm = false
    @State private var animatedSubtitle = ""
    @State private var typingTask: Task<Void, Never>?

    private var subtitleText: String {
        viewModel.isSignUp ? "Create Your Account" : "Welcome Back"
    }

    var body: some View {
        let accent = Color(red: 0.78, green: 0.09, blue: 0.2)

        return ZStack {
            LinearGradient(
                colors: [accent.opacity(0.95), accent.opacity(0.7), accent.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("Bliss")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)

                    Text(animatedSubtitle)
                        .foregroundStyle(.white.opacity(0.85))
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: animatedSubtitle)
                }
                .padding(.top, 60)

                if !showForm {
                    VStack(spacing: 14) {
                        Button {
                            viewModel.isSignUp = false
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                showForm = true
                            }
                        } label: {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )
                        .cornerRadius(28)
                        .ignoresSafeArea(edges: .bottom)

                        Button {
                            viewModel.isSignUp = true
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                showForm = true
                            }
                        } label: {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(Color.white)
                        .foregroundColor(accent)
                        .cornerRadius(28)
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)

            if showForm {
                VStack {
                    Spacer(minLength: 0)
                    authForm(accent: accent)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .task {
            startTyping()
        }
        .onChange(of: viewModel.isSignUp) { _ in
            startTyping()
        }
    }

    @ViewBuilder
    private func authForm(accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.isSignUp ? "Create Your Account" : "Hello\nSign in!")
                .font(.title2.weight(.bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 14) {
                AuthTextField(
                    icon: "envelope",
                    placeholder: "Email",
                    text: $viewModel.email,
                    showPassword: .constant(false)
                )

                AuthTextField(
                    icon: "lock",
                    placeholder: "Password",
                    text: $viewModel.password,
                    isSecure: true,
                    showPassword: $viewModel.showPassword
                )

                if viewModel.isSignUp {
                    AuthTextField(
                        icon: "lock",
                        placeholder: "Confirm Password",
                        text: $viewModel.confirmPassword,
                        isSecure: true,
                        showPassword: $viewModel.showConfirmPassword
                    )
                }
            }

            if let message = viewModel.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
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
            .background(accent)
            .foregroundColor(.white)
            .cornerRadius(24)
            .disabled(viewModel.isLoading)

            HStack {
                Spacer()
                Button(action: viewModel.toggleMode) {
                    let prefix = viewModel.isSignUp ? "Have account?" : "Don't have account?"
                    let action = viewModel.isSignUp ? "Sign in" : "Sign up"
                    Text("\(prefix)\n\(action)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(TopRoundedCorners(radius: 28))
        .shadow(color: .black.opacity(0.08), radius: 10, y: -4)
        .ignoresSafeArea(edges: .bottom)
    }

    private func startTyping() {
        typingTask?.cancel()
        animatedSubtitle = ""

        typingTask = Task {
            for character in subtitleText {
                try? await Task.sleep(nanoseconds: 35_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    animatedSubtitle.append(character)
                }
            }
        }
    }
}

private struct TopRoundedCorners: Shape {
    var radius: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(sessionStore: SessionStore()))
}
