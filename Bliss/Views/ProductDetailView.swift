import SwiftUI
import CoreLocation
import MapKit

struct ProductDetailView: View {
    let product: FirestoreProduct
    let userLocation: CLLocation
    @ObservedObject var sessionStore: SessionStore
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("savedMarketplaceProductIds") private var savedProductIdsData: Data = Data()
    @State private var showMessageAlert = false
    @State private var sellerUsername: String = ""
    @State private var sellerAvatarURL: String? = nil
    @State private var isMessagingSeller = false
    
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: product.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    var savedProductIds: [String] {
        (try? JSONDecoder().decode([String].self, from: savedProductIdsData)) ?? []
    }
    
    var isSaved: Bool {
        savedProductIds.contains(product.id ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Reduced hero image height
                AsyncImage(url: URL(string: product.imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipped()
                .cornerRadius(0)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(product.title)
                        .font(.title2.bold())
                        .fixedSize(horizontal: false, vertical: true)
                        
                    HStack(spacing: 10) {
                        if let avatarString = sellerAvatarURL, let url = URL(string: avatarString) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sellerUsername.isEmpty ? "Seller" : sellerUsername)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text("Posted on \(product.createdAt.formatted(.dateTime.month().day().year()))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.title.bold())
                    
                    Text("Condition: \(product.condition)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("Description")
                        .font(.headline)
                    Text(product.description)
                        .font(.body)
                    
                    Divider()
                    
                    Text("Location")
                        .font(.headline.bold())
                    
                    Map(coordinateRegion: .constant(region), annotationItems: [product]) { p in
                        MapMarker(coordinate: p.coordinate, tint: .red)
                    }
                    .frame(height: 180)
                    .cornerRadius(12)
                    
                    Text(product.locationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if product.sellerId != sessionStore.userId {
                        Button {
                            sendMessageToSeller()
                        } label: {
                            if isMessagingSeller {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            } else {
                                Text("Message Seller")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 12)
                        .disabled(isMessagingSeller)
                        .alert("Message Sent", isPresented: $showMessageAlert) {
                            Button("OK", role: .cancel) { dismiss() }
                        } message: {
                            Text("A marketplace message has been sent to \(sellerUsername.isEmpty ? "the seller" : sellerUsername).")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleSave) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .foregroundColor(isSaved ? .red : .primary)
                }
            }
        }
        .onAppear {
            fetchSeller()
        }
    }
    
    private func toggleSave() {
        guard let id = product.id else { return }
        var ids = savedProductIds
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.append(id)
        }
        if let data = try? JSONEncoder().encode(ids) {
            savedProductIdsData = data
        }
    }
    
    private func fetchSeller() {
        Task {
            do {
                let user = try await UserService().fetchUser(userId: product.sellerId)
                await MainActor.run {
                    self.sellerUsername = user.username
                    self.sellerAvatarURL = user.avatarURL
                }
            } catch {
                print("Failed to fetch seller: \(error)")
            }
        }
    }
    
    private func sendMessageToSeller() {
        Task {
            await MainActor.run { isMessagingSeller = true }
            do {
                let convService = ConversationService()
                let convId = try await convService.createConversation(
                    between: sessionStore.userId,
                    and: product.sellerId,
                    productId: product.id,
                    productTitle: product.title,
                    sellerUsername: sellerUsername.isEmpty ? nil : sellerUsername
                )
                let text = "I am interested in \(product.title). Is this still available?"
                try await convService.sendMessage(conversationId: convId, senderId: sessionStore.userId, text: text)
                
                await MainActor.run {
                    isMessagingSeller = false
                    showMessageAlert = true
                }
            } catch {
                await MainActor.run {
                    isMessagingSeller = false
                }
                print("Error sending message: \(error)")
            }
        }
    }
}
