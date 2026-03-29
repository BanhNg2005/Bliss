import SwiftUI
import PhotosUI
import CoreData
import FirebaseStorage
import FirebaseFirestore

struct CreatePostView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let authorId: String

    // Form fields
    @State private var caption = ""
    @State private var mediaType: MediaType = .image

    // Photo picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var previewImage: UIImage?

    // Upload state
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var errorMessage: String?

    var canPost: Bool {
        !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && selectedImageData != nil
        && !isUploading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Photo picker area
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: mediaType == .image ? .images : .videos
                    ) {
                        photoPickerLabel
                    }
                    .onChange(of: selectedItem) { newItem in
                        loadSelectedMedia(newItem)
                    }
                    .onChange(of: mediaType) { _ in
                        // Reset selection when media type changes
                        selectedItem = nil
                        selectedImageData = nil
                        previewImage = nil
                    }

                    // MARK: - Caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField("Write a caption…", text: $caption, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Media type picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Media Type")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Picker("Media Type", selection: $mediaType) {
                            ForEach(MediaType.allCases) { type in
                                Label(type.title, systemImage: type.systemImage).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Upload progress
                    if isUploading {
                        VStack(spacing: 8) {
                            ProgressView(value: uploadProgress)
                                .tint(.blue)
                            Text("Uploading… \(Int(uploadProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }

                    // MARK: - Error
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isUploading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { uploadAndSave() }
                        .fontWeight(.semibold)
                        .disabled(!canPost)
                }
            }
        }
    }

    // MARK: - Photo picker label view

    @ViewBuilder
    private var photoPickerLabel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .frame(height: 280)

            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Edit overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Label("Change", systemImage: "pencil")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(12)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)

                    Text("Tap to choose from gallery")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: previewImage != nil)
    }

    // MARK: - Load selected media from PhotosPicker

    private func loadSelectedMedia(_ item: PhotosPickerItem?) {
        guard let item else { return }
        errorMessage = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    errorMessage = "Could not load the selected media."
                    return
                }
                await MainActor.run {
                    selectedImageData = data
                    if let uiImage = UIImage(data: data) {
                        previewImage = uiImage
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load media: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Upload to Firebase Storage, then save post

    private func uploadAndSave() {
        guard let imageData = selectedImageData else { return }
        errorMessage = nil
        isUploading = true

        Task {
            do {
                let mediaURL = try await uploadToStorage(data: imageData)
                await savePost(mediaURL: mediaURL)
            } catch {
                await MainActor.run {
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                    isUploading = false
                }
            }
        }
    }

    private func uploadToStorage(data: Data) async throws -> String {
        let filename = "\(UUID().uuidString).\(mediaType == .image ? "jpg" : "mp4")"
        let path = "posts/\(authorId)/\(filename)"
        let ref = Storage.storage().reference().child(path)

        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = ref.putData(data, metadata: nil) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                ref.downloadURL { url, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                    }
                }
            }

            // Track upload progress on the main actor
            uploadTask.observe(.progress) { snapshot in
                let progress = Double(snapshot.progress?.completedUnitCount ?? 0)
                    / Double(snapshot.progress?.totalUnitCount ?? 1)
                Task { @MainActor in
                    uploadProgress = progress
                }
            }
        }
    }

    @MainActor
    private func savePost(mediaURL: String) {
        // Save to Core Data (local cache)
        let post = Post(context: viewContext)
        post.postId = UUID().uuidString
        post.authorId = authorId.isEmpty ? "user_unknown" : authorId
        post.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        post.mediaURL = mediaURL
        post.mediaType = mediaType.rawValue
        post.createdAt = Date()
        post.lastUpdated = Date()
        post.isLiked = false
        post.likeCount = 0

        do {
            try viewContext.save()
        } catch {
            errorMessage = "Saved to cloud but failed to cache locally."
        }

        // Also save to Firestore so other users can see it
        let db = Firestore.firestore()
        let postData: [String: Any] = [
            "postId": post.wrappedPostId,
            "authorId": post.wrappedAuthorId,
            "caption": post.wrappedCaption,
            "mediaURL": mediaURL,
            "mediaType": post.mediaType,
            "likeCount": 0,
            "likedBy": [],
            "createdAt": Date()
        ]
        db.collection("posts").document(post.wrappedPostId).setData(postData)

        isUploading = false
        dismiss()
    }
}

#Preview {
    CreatePostView(authorId: "user_1234")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
