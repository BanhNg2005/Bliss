// Views/DM/DMView.swift
import SwiftUI

struct DMView: View {
    @ObservedObject var sessionStore: SessionStore
    @StateObject private var service = ConversationService()
    @StateObject private var callService = CallService.shared
    @State private var showNewConversation = false

    var body: some View {
        NavigationStack {
            Group {
                if service.conversations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No messages yet")
                            .font(.title3.bold())
                        Text("Start a conversation by tapping +")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section(header: Text("Chats")) {
                            ForEach(service.conversations) { conversation in
                                NavigationLink {
                                    ChatView(
                                        conversation: conversation,
                                        sessionStore: sessionStore,
                                        callService:  CallService.shared 
                                    )
                                } label: {
                                    ConversationRowView(
                                        conversation: conversation,
                                        currentUserId: sessionStore.userId
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewConversation = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showNewConversation) {
                NewConversationView(sessionStore: sessionStore, service: service)
            }
            .onAppear {
                service.listenToConversations(for: sessionStore.userId)
                UserService().setOnlineStatus(userId: sessionStore.userId, isOnline: true)
                CallService.shared.listenForIncomingCalls(userId: sessionStore.userId)
            }
            .onDisappear {
                service.stopListeningToConversations()
                UserService().setOnlineStatus(userId: sessionStore.userId, isOnline: false)
            }
        }
    }
}
