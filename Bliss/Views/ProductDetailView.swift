import SwiftUI
import CoreLocation
import MapKit

struct ProductDetailView: View {
    let product: FirestoreProduct
    let userLocation: CLLocation
    @ObservedObject var sessionStore: SessionStore
    @Environment(\.dismiss) var dismiss
    
    @State private var showMessageAlert = false
    @State private var sellerUsername: String = ""
    
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: product.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Large Image
                AsyncImage(url: URL(string: product.imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 300)
                .clipped()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(product.title)
                        .font(.title2.bold())
                        
                    if !sellerUsername.isEmpty {
                        Text("Listed by \(sellerUsername)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
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
                    
                    Text("Rental Location")
                        .font(.headline.bold())
                    
                    Map(coordinateRegion: .constant(region), annotationItems: [product]) { p in
                        MapMarker(coordinate: p.coordinate, tint: .red)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    
                    Text(product.locationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        sendMessageToSeller()
                    } label: {
                        Text("Message Seller")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 16)
                    .alert("Message Sent", isPresented: $showMessageAlert) {
                        Button("OK", role: .cancel) { dismiss() }
                    } message: {
                        Text("An automated message has been sent to the seller.")
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchSeller()
        }
    }
    
    private func fetchSeller() {
        Task {
            do {
                let user = try await UserService().fetchUser(userId: product.sellerId)
                await MainActor.run {
                    self.sellerUsername = user.username
                }
            } catch {
                print("Failed to fetch seller: \(error)")
            }
        }
    }
    
    private func sendMessageToSeller() {
        Task {
            do {
                let convService = ConversationService()
                let convId = try await convService.createConversation(between: sessionStore.userId, and: product.sellerId)
                let text = "I am interested in \(product.title). Is this still available?"
                try await convService.sendMessage(conversationId: convId, senderId: sessionStore.userId, text: text)
                
                await MainActor.run {
                    showMessageAlert = true
                }
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
}
