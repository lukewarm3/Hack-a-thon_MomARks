//
//  PlaceAnnotation.swift
//  ARMap
//
//  Created by Luke Cao on 3/22/25.
//

import SwiftUI

struct PlaceAnnotationView: View {
    let place: Place
    let isSelected: Bool

    var body: some View {
        Text("🦣")
            //.foregroundColor(.red)
            .font(.system(size: 30))
            .padding(8)
            .background(
                Circle()
                    .fill(.white)
                    .frame(width: 50, height: 50)
            )
            .frame(width: 50, height: 50)
            .scaleEffect(isSelected ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}
