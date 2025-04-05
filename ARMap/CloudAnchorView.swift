//
//  CloudAnchorView.swift
//  ARMap
//
//  Created by Luke Cao on 3/21/25.
//

import SwiftUI

/// View for hosting or resolving anchors.
struct CloudAnchorView: View {
  @EnvironmentObject var manager: CloudAnchorManager

  var body: some View {
    ZStack {
      ARViewContainer()
        .ignoresSafeArea()
        .onTapGesture { manager.tapPoint($0) }
      VStack {
        Spacer()
          .frame(height: 50)
        ZStack {
          Rectangle()
          Text(manager.messageLabel)
            .frame(width: 233, height: 50)
            .font(.system(size: 17))
            .foregroundStyle(.white)
            .lineLimit(3)
            .multilineTextAlignment(.center)
        }
        .frame(width: 243, height: 60)
        .opacity(0.5)
        Spacer()
        ZStack {
          Rectangle()
          Text(manager.debugLabel)
            .padding(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(size: 12))
            .foregroundStyle(.white)
            .lineLimit(5)
            .multilineTextAlignment(.leading)
        }
        .frame(height: 100)
        .opacity(0.5)
      }
      .ignoresSafeArea(edges: .bottom)
        

      if manager.showAnchorNameDialog {
            Group {
                // Background dimming view
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // Your custom alert view
                CustomAlertView(
                    isPresented: $manager.showAnchorNameDialog,
                    anchorName: $manager.anchorNameDialogField,
                    anchorDescription: $manager.anchorDescriptionDialogField
                )
            }
            .transition(.scale)
        }
    }
    .animation(.easeInOut, value: manager.showAnchorNameDialog)
  }
}
