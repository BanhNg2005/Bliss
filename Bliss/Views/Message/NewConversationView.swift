import SwiftUI
import CoreData

struct NewConversationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let currentUserId: String

    @State private var recipientId = ""
    @State private var errorMessage: String?

    private let accent = Color(red: 0.78, green: 0.09, blue: 0.2)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                        TextField("Username or User ID", text: $recipientId)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("New Message")
                } footer: {
                    Text("Enter the user ID of the person you want to message.")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        startConversation()
                    }
                    .disabled(recipientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func startConversation() {
        let trimmed = recipientId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a user ID."
            return
        }

        guard trimmed != currentUserId else {
            errorMessage = "You can't message yourself."
            return
        }

        // Check if conversation already exists
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", trimmed)
        request.fetchLimit = 1

        if let existing = try? viewContext.fetch(request), !existing.isEmpty {
            // Conversation already exists, just dismiss
            dismiss()
            return
        }

        // Create new conversation
        let conversation = Conversation(context: viewContext)
        conversation.conversationId = trimmed
        conversation.lastMessageAt = Date()
        conversation.lastMessageText = ""
        conversation.unreadCount = 0

        try? viewContext.save()
        dismiss()
    }
}