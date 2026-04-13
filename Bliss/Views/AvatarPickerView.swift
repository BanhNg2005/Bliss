import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore

struct AvatarPickerView: View {
    let userId: String
    @Binding var avatarURL: String?

    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar image
            Group {
                if let urlString = avatarURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            avatarPlaceholder
                        case .failure:
                            avatarPlaceholder
                        @unknown default:
                            avatarPlaceholder
                        }
                    }
                } else {
                    avatarPlaceholder
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 3))

            // Upload progress overlay
            if isUploading {
                Circle()
                    .fill(.black.opacity(0.4))
                    .frame(width: 96, height: 96)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }

            // Edit button
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 28, height: 28)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
            }
            .onChange(of: selectedItem) { newItem in
                guard let newItem else { return }
                uploadAvatar(item: newItem)
            }
            .disabled(isUploading)
        }
        .overlay(alignment: .bottom) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .offset(y: 20)
            }
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Upload

    private func uploadAvatar(item: PhotosPickerItem) {
        isUploading = true
        errorMessage = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        errorMessage = "Could not load image."
                        isUploading = false
                    }
                    return
                }

                // Compress image before uploading to save storage
                let compressed = compressImage(data: data, maxSizeKB: 300) ?? data

                // Upload to Firebase Storage
                let path = "avatars/\(userId)/avatar.jpg"
                let ref = Storage.storage().reference().child(path)
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"

                let downloadURL: String = try await withCheckedThrowingContinuation { continuation in
                    ref.putData(compressed, metadata: metadata) { _, error in
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
                }

                // Update Firestore user document
                try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .updateData(["avatarURL": downloadURL])

                await MainActor.run {
                    avatarURL = downloadURL
                    isUploading = false
                }

            } catch {
                await MainActor.run {
                    errorMessage = "Upload failed."
                    isUploading = false
                }
            }
        }
    }

    // Compress image to stay under maxSizeKB
    private func compressImage(data: Data, maxSizeKB: Int) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        var quality: CGFloat = 0.8
        var compressed = image.jpegData(compressionQuality: quality)
        while let c = compressed, c.count > maxSizeKB * 1024, quality > 0.1 {
            quality -= 0.1
            compressed = image.jpegData(compressionQuality: quality)
        }
        return compressed
    }
}