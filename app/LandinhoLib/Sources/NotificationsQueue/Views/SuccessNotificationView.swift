//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import Foundation
import SwiftUI

struct SuccessNotificationView: View {
  let text: String

  var body: some View {
    HStack {
      Image(systemName: "checkmark.circle.fill")
        .font(.title)
      Text(text)
      Spacer()
    }
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity)
    .padding()
    .background(.green)
  }
}

#Preview {
  SuccessNotificationView(text: "Salvo com sucesso")
}
