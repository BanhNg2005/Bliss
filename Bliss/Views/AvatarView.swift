import SwiftUI

/// Reusable avatar used across posts, DMs, and profile lists.
struct AvatarView: View {
    let url: String?
    let username: String
    var size: CGFloat = 40
    var isOnline: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let urlString = url,
                   !urlString.isEmpty,
                   let imageURL = URL(string: urlString) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())

            // Online indicator dot
            if isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 1.5)
                    )
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            // Gradient background based on username initial for variety
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var initials: String {
        let first = username.first.map(String.init) ?? "?"
        return first.uppercased()
    }

    // Deterministic gradient based on username so same user always gets same color
    private var gradientColors: [Color] {
        let options: [[Color]] = [
            [.purple, .pink],
            [.blue, .teal],
            [.orange, .red],
            [.green, .teal],
            [.indigo, .purple],
            [.pink, .orange]
        ]
        let index = abs(username.hashValue) % options.count
        return options[index]
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(url: nil, username: "alice", size: 44, isOnline: true)
        AvatarView(url: nil, username: "bob", size: 44, isOnline: false)
        AvatarView(url: nil, username: "zoe", size: 44)
    }
    .padding()
}