//
//  CustomAlertView.swift
//  ARMap
//
//  Created by Luke Cao on 3/22/25.
//

import SwiftUI

struct CustomAlertView: View {
    @EnvironmentObject var manager: CloudAnchorManager
    @EnvironmentObject var locationManager: LocationManager
    
    @Binding var isPresented: Bool
    @Binding var anchorName: String
    @Binding var anchorDescription: String
    
    @State private var imageData: Data?
    @State private var showingImagePicker = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter Details")
                .font(.headline)
            TextField("Name", text: $anchorName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Description", text: $anchorDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Choose Image") {
                showingImagePicker = true
            }
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Spacer()
                Button("Save") {
                    if let location = locationManager.location {
                        print("current location is \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        manager.saveAnchor(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, imageData: imageData)
                    } else {
                        print("Error Getting Current Location")
                    }
                    isPresented = false
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(40)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imageData: $imageData)
        }
    }
}
