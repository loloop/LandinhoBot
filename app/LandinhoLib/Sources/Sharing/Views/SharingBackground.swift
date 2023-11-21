//
//  SharingBackground.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

import Foundation
import SwiftUI

// TODO: Remove the placeholder background and add an actual image for the background
struct SharingBackground: View {
  var body: some View {
    LinearGradient(
      colors: [
        .green,
        .yellow
      ],
      startPoint: .top,
      endPoint: .bottom)
    .overlay {
      Text("placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder placeholder")
        .bold()
        .font(.largeTitle)
        .foregroundStyle(.secondary.opacity(0.6))
        .visualEffect { content, geometryProxy in
          content.rotationEffect(.degrees(45))
        }
        .frame(width: 1080, height: 1080)
        .allowsHitTesting(false)
    }
    .clipped()
  }
}

#Preview {
  SharingBackground()
}



