import SwiftUI

struct CallButton: View {
    let conversation: FirestoreConversation
    let currentUserId: String
    @ObservedObject var callService: CallService

    @State private var currentUser: FirestoreUser?
    @State private var isLoading = false

    var body: some View {
        Button {
            initiateCall()
        } label: {
            Image(systemName: callService.callState == .idle ? "phone.fill" : "phone.down.fill")
                .font(.system(size: 18))
                .foregroundStyle(callService.callState == .idle ? .green : .red)
        }
        .disabled(isLoading || callService.callState != .idle)
        .task {
            currentUser = try? await UserService().fetchUser(userId: currentUserId)
        }
    }

    private func initiateCall() {
        guard let currentUser else { return }
        isLoading = true
        let otherUser = FirestoreUser(
            userId: conversation.otherUserId,
            username: conversation.otherUsername,
            email: "",
            avatarURL: conversation.otherAvatarURL,
            createdAt: Date(),
            isOnline: conversation.isOtherOnline,
            lastSeen: Date()
        )
        Task {
            try? await callService.startCall(to: otherUser, from: currentUser)
            isLoading = false
        }
    }
}