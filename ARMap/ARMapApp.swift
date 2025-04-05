//
//  ARMapApp.swift
//  ARMap
//
//  Created by Luke Cao on 3/21/25.
//

import SwiftUI

@main
struct MainApp: App {
  @StateObject private var manager = CloudAnchorManager()
  @StateObject private var locationManager = LocationManager()
    
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(locationManager)
        .environmentObject(manager)
    }
  }
}
