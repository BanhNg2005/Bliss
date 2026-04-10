import SwiftUI

struct CreateListingView: View {
    @ObservedObject var service: MarketplaceService
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var priceString = ""
    @State private var condition = "New"
    @State private var descriptionText = ""
    @State private var locationName = "San Francisco, CA"
    
    let conditions = ["New", "Used - Like New", "Used - Good", "Used - Fair"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextField("Price", text: $priceString)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Condition")) {
                    Picker("Condition", selection: $condition) {
                        ForEach(conditions, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $descriptionText)
                        .frame(height: 100)
                }
                
                Section(header: Text("Location")) {
                    TextField("Location Name", text: $locationName)
                }
                
                Section {
                    Button("Create Listing") {
                        Task {
                            guard let price = Double(priceString) else { return }
                            let sessionUserId = "current_user_id" // Use session id logic here
                            try? await service.createProduct(
                                title: title,
                                description: descriptionText,
                                price: price,
                                condition: condition,
                                locationName: locationName,
                                lat: 37.7749,
                                lon: -122.4194,
                                sellerId: sessionUserId
                            )
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("New Listing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
