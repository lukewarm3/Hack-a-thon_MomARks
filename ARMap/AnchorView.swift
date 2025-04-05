//
//  ContentView.swift
//  ARMap
//
//  Created by Luke Cao on 3/21/25.
//

import RealityKit
import SwiftUI

/// View for choosing hosting or resolving; root of navigation stack.
struct AnchorView: View {
    @EnvironmentObject var manager: CloudAnchorManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack(path: $manager.navigationPath) {
            ScrollView {
                VStack(spacing: 25) {
                    // App Title
                    Text("MomARks")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .padding(.top, 20)
                    
                    // Host Card
                    VStack(spacing: 20) {
                        Image(systemName: "arrow.up.doc.on.clipboard")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                        
                        Text("Post your Moment")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("Scan your space and create a new Cloud Moment accessible by others")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            manager.beginHostingButtonPressed()
                        } label: {
                            HStack {
                                Text("Begin Posting")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(minWidth: 200)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .opacity(0.3)
                        
                        Text("OR")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                        
                        Rectangle()
                            .frame(height: 1)
                            .opacity(0.3)
                    }
                    .padding(.horizontal, 40)
                    
                    // Resolve Card
                    VStack(spacing: 20) {
                        Image(systemName: "arrow.down.doc.on.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("See Others' Moments")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("Localize this device against previously created Cloud Moments")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            manager.beginResolvingButtonPressed()
                        } label: {
                            HStack {
                                Text("Discover Nearby Moments")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(minWidth: 200)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Footer or help text
                    Text("Choose an option to get started with AR anchors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal)
            }
            .navigationDestination(for: CloudAnchorManager.Page.self) { page in
                switch page {
                case .host:
                    CloudAnchorView()
                case .resolve:
                    CloudAnchorView()
                case .resolvePicker:
                    ResolvePickerView()
                }
            }
        }
        .environmentObject(manager)
        .alert("Experience it together", isPresented: $manager.showPrivacyNotice) {
            Button(role: .destructive) {
                manager.acceptPrivacyNotice()
            } label: {
                Text("Start now")
            }
            Link("Learn more", destination: URL(string: "https://developers.google.com/ar/data-privacy")!)
            Button(role: .cancel) {
            } label: {
                Text("Not now")
            }
        } message: {
            Text("To power this session, Google will process visual data from your camera.")
        }
    }
}

#Preview {
    AnchorView()
        .environmentObject(CloudAnchorManager())
}
