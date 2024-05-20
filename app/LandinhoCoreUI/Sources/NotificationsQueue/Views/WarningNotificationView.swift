//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import Foundation
import SwiftUI

struct WarningNotificationView: View {
  let text: String

  var body: some View {
    HStack {
      Image(systemName: "exclamationmark.triangle")
        .font(.title)
      Text(text)
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(.yellow)
  }
}
