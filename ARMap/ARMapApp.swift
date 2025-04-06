//
//  ARMapApp.swift
//  ARMap
//
//  Created by Luke Cao on 3/21/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct MainApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
