//
//  SharingBackground.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

import SwiftUI

struct SharingBackground: View {
  var body: some View {
    GeometryReader { geometry in
      Image(decorative: "SharingCircuit", bundle: .module)
        .resizable()
        .scaledToFill()
        .frame(width: geometry.size.width, height: geometry.size.height)
        .overlay(.black.opacity(0.2))
        .clipped()
    }
  }
}

#Preview {
  SharingBackground()
}
