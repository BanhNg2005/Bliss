import SwiftUI
import PhotosUI
import MapKit
import CoreLocation

struct MapPinPickerView: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var postalCode: String
    @Binding var city: String
    @Environment(\.dismiss) var dismiss
    
    @State private var cameraPosition: MapCameraPosition
    
    init(lat: Binding<Double>, lon: Binding<Double>, postal: Binding<String>, city: Binding<String>) {
        self._latitude = lat
        self._longitude = lon
        self._postalCode = postal
        self._city = city
        let coordinate = CLLocationCoordinate2D(latitude: lat.wrappedValue, longitude: lon.wrappedValue)
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)))
    }
    
    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    Marker("Location", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        .tint(.blue)
                }
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        latitude = coordinate.latitude
                        longitude = coordinate.longitude
                        reverseGeocode()
                    }
                }
            }
            .navigationTitle("Pin Your Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func reverseGeocode() {
        let loc = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) { placemarks, error in
            if let pm = placemarks?.first {
                if let zip = pm.postalCode {
                    // Extract just the first 3 chars assuming Canadian format H1M, or keep full ZIP
                    // The prompt asked for 'like default postal code is H1M'
                    self.postalCode = zip.count > 3 ? String(zip.prefix(3)).uppercased() : zip
                }
                if let locality = pm.locality {
                    self.city = locality
                }
            }
        }
    }
}

struct CreateListingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var service: MarketplaceService
    @ObservedObject var sessionStore: SessionStore
    
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var priceString = ""
    @State private var condition = "New"
    
    // Location Data
    @State private var postalCode = ""
    @State private var city = ""
    @State private var latitude: Double = 37.7749
    @State private var longitude: Double = -122.4194
    @State private var showMapPicker = false
    
    // Photos
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var selectedUIImage: UIImage? = nil
    
    @StateObject private var locationManager = MarketplaceLocationManager()
    
    @State private var isSubmitting = false
    @State private var showError = false
    
    let conditions = ["New", "Used - Like New", "Used - Good", "Used - Fair"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Photo Picker card
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            if let uiImage = selectedUIImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(height: 220)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 40))
                                            Text("Add Photos")
                                                .font(.headline)
                                        }
                                        .foregroundColor(.blue)
                                    }
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                self.selectedUIImage = uiImage
                                // highly compress to bypass 1MB firestore limit. In real prods use Firebase Storage
                                self.selectedImageData = uiImage.jpegData(compressionQuality: 0.1)
                            }
                        }
                    }
                    
                    // Fields Card
                    VStack(spacing: 16) {
                        TextField("Title", text: $title)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        
                        TextField("Price ($)", text: $priceString)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        
                        HStack {
                            Text("Condition")
                            Spacer()
                            Picker("Condition", selection: $condition) {
                                ForEach(conditions, id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }
                            .tint(.primary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        TextEditor(text: $descriptionText)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(alignment: .topLeading) {
                                if descriptionText.isEmpty {
                                    Text("Description (Recommended)")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                    
                    // Location Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Location")
                                .font(.headline)
                            Spacer()
                            Button("Use Current Location") {
//                                locationManager.requestLocation()
                                locationManager.requestLocation()
                            }
                            .font(.subheadline)
                        }
                        
                        Button {
                            showMapPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.blue)
                                
                                if postalCode.isEmpty {
                                    Text("Tap to pin approximate location")
                                        .foregroundColor(.gray)
                                } else {
                                    Text("\(city.isEmpty ? "" : city + ", ")\(postalCode)")
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Submit button
                    Button {
                        submitProduct()
                    } label: {
                        if isSubmitting {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        } else {
                            Text("Publish Listing")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 16)
                    .disabled(title.isEmpty || priceString.isEmpty || selectedImageData == nil || postalCode.isEmpty || isSubmitting)
                }
                .padding()
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showMapPicker) {
                MapPinPickerView(lat: $latitude, lon: $longitude, postal: $postalCode, city: $city)
            }
            .onReceive(locationManager.$location) { newLocation in
                if let loc = newLocation {
                    self.latitude = loc.coordinate.latitude
                    self.longitude = loc.coordinate.longitude
                    
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(loc) { placemarks, error in
                        if let pm = placemarks?.first {
                            if let zip = pm.postalCode {
                                self.postalCode = zip.count > 3 ? String(zip.prefix(3)).uppercased() : zip
                            }
                            if let locality = pm.locality {
                                self.city = locality
                            }
                        }
                    }
                }
            }
        }
    }
    
    func submitProduct() {
        guard let price = Double(priceString), !title.isEmpty, selectedImageData != nil else { return }
        isSubmitting = true
        Task {
            do {
                let sessionUserId = sessionStore.userId
                let finalLocationName = "\(city.isEmpty ? "" : city + " ")\(postalCode)"
                
                try await service.createProduct(
                    title: title,
                    description: descriptionText.isEmpty ? "No description provided." : descriptionText,
                    price: price,
                    condition: condition,
                    locationName: finalLocationName,
                    postalCode: postalCode,
                    lat: latitude,
                    lon: longitude,
                    sellerId: sessionUserId,
                    imageData: selectedImageData
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to map item: \(error)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}
