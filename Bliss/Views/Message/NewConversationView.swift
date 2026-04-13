// Views/DM/NewConversationView.swift
import SwiftUI

struct NewConversationView: View {
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var service: ConversationService
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var results: [FirestoreUser] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var navigateToConversation: FirestoreConversation? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search username...", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit { search() }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

                if isSearching {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding()
                } else {
                    List(results) { user in
                        Button {
                            startConversation(with: user)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.gray.opacity(0.4))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.username)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    if user.isOnline {
                                        Text("Online")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    } else {
                                        Text("Last seen \(user.lastSeen, style: .relative) ago")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Search") { search() }
                        .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationDestination(item: $navigateToConversation) { conversation in
                ChatView(conversation: conversation, sessionStore: sessionStore, callService: CallService.shared)
            }
        }
    }

    private func search() {
        isSearching = true
        errorMessage = nil
        Task {
            do {
                let found = try await UserService().searchUsers(username: searchText.trimmingCharacters(in: .whitespaces))
                results = found.filter { $0.userId != sessionStore.userId }
                if results.isEmpty { errorMessage = "No users found." }
            } catch {
                errorMessage = "Search failed. Try again."
            }
            isSearching = false
        }
    }

    private func startConversation(with user: FirestoreUser) {
        Task {
            do {
                let convId = try await service.createConversation(
                    between: sessionStore.userId,
                    and: user.userId
                )
                let conversation = FirestoreConversation(
                    conversationId: convId,
                    participantIds: [sessionStore.userId, user.userId],
                    lastMessageText: "",
                    lastMessageAt: Date(),
                    conversationType: .direct,
                    productId: nil,
                    productTitle: nil,
                    sellerId: nil,
                    sellerUsername: nil,
                    otherUsername: user.username,
                    otherUserId: user.userId,
                    otherAvatarURL: user.avatarURL,
                    isOtherOnline: user.isOnline
                )
                await MainActor.run {
                    navigateToConversation = conversation
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not start conversation."
                }
            }
        }
    }
}
