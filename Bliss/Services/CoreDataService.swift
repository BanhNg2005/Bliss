import CoreData
import FirebaseFirestore

/// Writes Firestore data into Core Data. All methods run on the view context.
@MainActor
final class CoreDataService {
    static let shared = CoreDataService()
    private let context: NSManagedObjectContext

    private init() {
        context = PersistenceController.shared.container.viewContext
    }

    // MARK: - User

    func upsertUser(_ firestoreUser: FirestoreUser) {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", firestoreUser.userId)
        request.fetchLimit = 1

        let user = (try? context.fetch(request))?.first ?? User(context: context)
        user.userId = firestoreUser.userId
        user.username = firestoreUser.username
        user.avatarURL = firestoreUser.avatarURL
        user.lastUpdated = firestoreUser.lastSeen

        saveContext()
    }

    // MARK: - Conversation

    func upsertConversation(_ firestoreConv: FirestoreConversation) {
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", firestoreConv.conversationId)
        request.fetchLimit = 1

        let conv = (try? context.fetch(request))?.first ?? Conversation(context: context)
        conv.conversationId = firestoreConv.conversationId
        conv.lastMessageText = firestoreConv.lastMessageText
        conv.lastMessageAt = firestoreConv.lastMessageAt

        saveContext()
    }

    // MARK: - Message

    @discardableResult
    func upsertMessage(_ firestoreMsg: FirestoreMessage) -> Message {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "messageId == %@", firestoreMsg.messageId)
        request.fetchLimit = 1

        let message = (try? context.fetch(request))?.first ?? Message(context: context)
        message.messageId = firestoreMsg.messageId
        message.senderId = firestoreMsg.senderId
        message.text = firestoreMsg.text
        message.mediaURL = firestoreMsg.mediaURL
        message.timestamp = firestoreMsg.timestamp
        message.status = firestoreMsg.isRead

        // Link to parent conversation
        let convRequest: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        convRequest.predicate = NSPredicate(format: "conversationId == %@", firestoreMsg.conversationId)
        convRequest.fetchLimit = 1
        if let conv = (try? context.fetch(convRequest))?.first {
            message.conversation = conv
        }

        saveContext()
        return message
    }

    // MARK: - Bulk helpers

    func upsertConversations(_ list: [FirestoreConversation]) {
        list.forEach { upsertConversation($0) }
    }

    func upsertMessages(_ list: [FirestoreMessage]) {
        list.forEach { upsertMessage($0) }
    }

    // MARK: - Save

    private func saveContext() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}