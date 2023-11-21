//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import Foundation
import SwiftUI

struct CriticalErrorView: View {
  let text: String

  var body: some View {
    HStack {
      Image(systemName: "xmark.octagon")
        .font(.title)
      Text(text)
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(.red)
  }
}

