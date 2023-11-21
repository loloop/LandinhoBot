//
//  AppWatermark.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

import Foundation
import SwiftUI

struct AppWatermark: View {
  var body: some View {
    HStack {
      // TODO: Resize and compress this
      Image("AppIcon", bundle: .module)
        .resizable()
        .frame(width: 30, height: 30)
        .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
      Text("Criado com **vroomvroom.racing**")
        .font(.caption)
    }
  }
}
