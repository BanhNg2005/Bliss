import SwiftUI
import CoreData

struct ConversationsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let currentUserId: String

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.lastMessageAt, ascending: false)],
        animation: .default
    )
    private var conversations: FetchedResults<Conversation>

    @State private var showNewMessage = false

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            NavigationLink(destination:
                                ChatView(conversation: conversation, currentUserId: currentUserId)
                                    .environment(\.managedObjectContext, viewContext)
                            ) {
                                ConversationRowView(conversation: conversation)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteConversations)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewMessage = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showNewMessage) {
                NewConversationView(currentUserId: currentUserId)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Messages Yet")
                .font(.title3.bold())

            Text("Start a conversation by tapping the compose button above.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(conversations[index])
        }
        try? viewContext.save()
    }
}