//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 20/11/23.
//

import Foundation
import SwiftUI

struct ShareButton: View {

  @State var hasTappedShare = false

  var body: some View {
    shareButton()
  }

  @MainActor
  func shareButton() -> some View {
    Button(action: {
      withAnimation(.interpolatingSpring) {
        hasTappedShare.toggle()
//        _ = viewStore.send(.onShareTap)
//        render(isSquareAspectRatio: viewStore.isSquareAspectRatio)
      }
    }, label: {
      if hasTappedShare {
        ProgressView()
          .tint(.white)
          .padding(10)
      } else {
        Text("Compartilhar")
          .foregroundStyle(.white)
          .font(.caption)
          .padding(12)
          .padding(.horizontal, 5)
      }
    })
    .foregroundStyle(.white)
    .background(.black)
    .overlay {
      RoundedRectangle(cornerRadius: 25.0, style: .continuous)
        .stroke(.white, lineWidth: 1)
    }
    .frame(maxHeight: .infinity, alignment: .bottom)
  }
}

#Preview {
  ShareButton()
}
