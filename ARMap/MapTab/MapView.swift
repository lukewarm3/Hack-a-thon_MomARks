//
//  MapView.swift
//  ARMap
//
//  Created by Luke Cao on 3/21/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var manager: CloudAnchorManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTag: String?
    @State private var places: [Place] = []
    
    @Binding var selection: ContentView.Tab  // used to navigate to the AnchorView automatically
    
    private var selectedPlace: Place? {
        guard let selectedTag = selectedTag else { return nil }
        return places.first { $0.id == selectedTag }
    }
    
    private func updateAnchorInfos() {
        guard let currentLocation = locationManager.location else {
            print("Location not yet available.")
            return
        }
        
        places = manager.fetchAndPruneAnchors(
            currentlatitude: currentLocation.coordinate.latitude,
            currentlongitude: currentLocation.coordinate.longitude
        )
        
        places = [
            Place(
                id: "1",
                name: "Duncan Student Center",
                age: "30m",
                description: "This is the Duncan Student Center.",
                latitude: 41.69878133392592,
                longitude: -86.23516434558917
            ),
            Place(
                id: "2",
                name: "Hesburgh Library",
                age: "30m",
                description: "I am taking Hackathon Competition here!",
                latitude: 41.70258141723964,
                longitude: -86.23419551824554
            ),
            Place(
                id: "3",
                name: "Starbucks",
                age: "30m",
                description: "The Iced Hazelnut Oatmilk Shaken Espresso is my favorite!",
                latitude: 41.702084780632184,
                longitude: -86.23757510148786
            ),
        ]
        
    }

    private var mapContent: some View {
        Map(selection: $selectedTag) {
            ForEach(places) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    PlaceAnnotationView(place: place, isSelected: selectedTag == place.id)
                        .onTapGesture {
                            selectedTag = place.id
                        }
                }
                .tag(place.id)
            }
            
            UserAnnotation()
        }
    }
    
    // Extract the bottom inset view
    private var bottomInset: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Selected Place")
                    .font(.headline)
                
                Text(selectedPlace?.description ?? "No place selected")
                    .font(.subheadline)
                
                if let placeId = selectedPlace?.id {
                    HStack {
                        Spacer()
                        Button {
                            selection = .anchor
                            manager.resolveButtonPressed(anchorIds: [placeId])
                        } label: {
                            Text("See It")
                                .font(.subheadline)
                                .padding()
                                .foregroundStyle(.white)
                                .background(.blue)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.3), value: selectedPlace?.id)
        }
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
    }
    
    // Extract the map controls view
    private var mapControlsView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            MapUserLocationButton()
            MapScaleView()
        }
        .padding()
    }
    
    var body: some View {
        mapContent
            .safeAreaInset(edge: .bottom) { bottomInset }
            .mapControls { mapControlsView }
            .onAppear {
              // Refresh anchor info every time the view appears on screen.
              updateAnchorInfos()
            }
            .onChange(of: locationManager.location) { _ in
                updateAnchorInfos()
            }
    }
}

// MARK: - Preview
#Preview {
    MapView(selection: .constant(ContentView.Tab.map))
        .environmentObject(LocationManager())
        .environmentObject(CloudAnchorManager())
}
