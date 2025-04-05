//
//  ContentView.swift
//  ARMap
//
//  Created by Luke Cao on 3/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .map


    enum Tab {
        case map
        case anchor
    }


    var body: some View {
        TabView(selection: $selection) {
            MapView(selection: $selection)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(Tab.map)


            AnchorView()
                .tabItem {
                    Label("Around", systemImage: "star")
                }
                .tag(Tab.anchor)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(CloudAnchorManager())
}
