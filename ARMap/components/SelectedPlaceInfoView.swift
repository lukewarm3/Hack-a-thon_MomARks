//
//  SelectedPlaceView.swift
//  ARMap
//
//  Created by Luke Cao on 3/22/25.
//

import SwiftUI

struct SelectedPlaceInfoView: View {
    let place: Place?  // This is nil if nothing is selected

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Selected Place")
                    .font(.headline)
                
                Text(place?.description ?? "No place selected")
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
    }
}
