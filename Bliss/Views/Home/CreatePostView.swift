import SwiftUI
import CoreData
struct CreatePostView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let authorId: String

    @State private var caption = ""
    @State private var mediaURL = ""
    @State private var mediaType: MediaType = .image
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Post") {
                    TextField("Caption", text: $caption)
                    TextField("Media URL", text: $mediaURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)

                    Picker("Media Type", selection: $mediaType) {
                        ForEach(MediaType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                }

                if let message = errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Post")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        savePost()
                    }
                    .disabled(isSaving || caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func savePost() {
        errorMessage = nil
        isSaving = true

        let post = Post(context: viewContext)
        post.postId = UUID().uuidString
        post.authorId = authorId.isEmpty ? "user_unknown" : authorId
        post.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        post.mediaURL = mediaURL.trimmingCharacters(in: .whitespacesAndNewlines)
        post.mediaType = mediaType.rawValue
        post.createdAt = Date()
        post.lastUpdated = Date()
        post.isLiked = false
        post.likeCount = 0

        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Unable to save this post."
            isSaving = false
        }
    }
}

#Preview {
    CreatePostView(authorId: "user_1234")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
