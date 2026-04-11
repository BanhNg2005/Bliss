import SwiftUI
import PhotosUI
import CoreData
import FirebaseStorage
import FirebaseFirestore

struct CreatePostView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let authorId: String

    @State private var caption = ""
    @State private var mediaType: MediaType = .image

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedMediaData: Data?
    @State private var previewImage: UIImage?

    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var errorMessage: String?

    var canPost: Bool {
        !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && selectedMediaData != nil
        && !isUploading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Photo / Video picker
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
                        selectedItem = nil
                        selectedMediaData = nil
                        previewImage = nil
                        errorMessage = nil
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

    // MARK: - Picker label

    @ViewBuilder
    private var photoPickerLabel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .frame(height: 280)

            if mediaType != .image, selectedMediaData != nil {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Video selected")
                        .font(.subheadline.weight(.semibold))
                    Text("Tap to change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

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
                    Image(systemName: mediaType == .image ? "photo.badge.plus" : "video.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Tap to choose from gallery")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: selectedMediaData != nil)
    }

    // MARK: - Load selected media

    private func loadSelectedMedia(_ item: PhotosPickerItem?) {
        guard let item else { return }
        errorMessage = nil
        selectedMediaData = nil
        previewImage = nil

        Task {
            do {
                if mediaType == .image {
                    // Images load fine as Data
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        await MainActor.run { errorMessage = "Could not load image." }
                        return
                    }
                    await MainActor.run {
                        selectedMediaData = data
                        previewImage = UIImage(data: data)
                    }
                } else {
                    // Videos must be loaded as a file URL then read from disk
                    // loadTransferable(type: Data.self) silently fails for large videos
                    guard let url = try await item.loadTransferable(type: URL.self) else {
                        // Fallback for simulator — try Data directly
                        if let data = try? await item.loadTransferable(type: Data.self),
                           !data.isEmpty {
                            await MainActor.run { selectedMediaData = data }
                        } else {
                            await MainActor.run {
                                errorMessage = "Could not load video. Try a shorter clip."
                            }
                        }
                        return
                    }

                    // Copy to a temp path we control so we can read it safely
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + ".mp4")
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    let data = try Data(contentsOf: tempURL)
                    try? FileManager.default.removeItem(at: tempURL)

                    await MainActor.run { selectedMediaData = data }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Upload to Firebase Storage then save

    private func uploadAndSave() {
        guard let mediaData = selectedMediaData else { return }
        errorMessage = nil
        isUploading = true
        uploadProgress = 0

        Task {
            do {
                let mediaURL = try await uploadToStorage(data: mediaData)
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
        let ext      = mediaType == .image ? "jpg" : "mp4"
        let mimeType = mediaType == .image ? "image/jpeg" : "video/mp4"
        let filename = "\(UUID().uuidString).\(ext)"
        let path     = "posts/\(authorId)/\(filename)"
        let ref      = Storage.storage().reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = mimeType

        return try await withCheckedThrowingContinuation { continuation in
            let task = ref.putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                ref.downloadURL { url, error in
                    if let error { continuation.resume(throwing: error) }
                    else if let url { continuation.resume(returning: url.absoluteString) }
                    else { continuation.resume(throwing: URLError(.badServerResponse)) }
                }
            }

            task.observe(.progress) { snapshot in
                let progress = Double(snapshot.progress?.completedUnitCount ?? 0)
                    / Double(max(snapshot.progress?.totalUnitCount ?? 1, 1))
                Task { @MainActor in uploadProgress = progress }
            }
        }
    }

    @MainActor
    private func savePost(mediaURL: String) {
        let post      = Post(context: viewContext)
        post.postId   = UUID().uuidString
        post.authorId = authorId.isEmpty ? "user_unknown" : authorId
        post.caption  = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        post.mediaURL = mediaURL
        post.mediaType   = mediaType.rawValue
        post.createdAt   = Date()
        post.lastUpdated = Date()
        post.isLiked     = false
        post.likeCount   = 0

        try? viewContext.save()

        Firestore.firestore().collection("posts").document(post.wrappedPostId).setData([
            "postId":    post.wrappedPostId,
            "authorId":  post.wrappedAuthorId,
            "caption":   post.wrappedCaption,
            "mediaURL":  mediaURL,
            "mediaType": post.mediaType,
            "likeCount": 0,
            "likedBy":   [],
            "createdAt": Date()
        ])

        isUploading = false
        dismiss()
    }
}

#Preview {
    CreatePostView(authorId: "user_1234")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
