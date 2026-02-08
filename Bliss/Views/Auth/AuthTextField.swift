//
//  AuthTextField.swift
//  Bliss
//
//  Created by Bu on 7/2/26.
//

import SwiftUI

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @Binding var showPassword: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)

                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }

                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 8)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3))
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var showPassword = false

        var body: some View {
            AuthTextField(
                icon: "lock",
                placeholder: "Password",
                text: $text,
                isSecure: true,
                showPassword: $showPassword
            )
            .padding()
            .background(Color(white: 0.95))
        }
    }

    return PreviewWrapper()
}
