//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 15/11/23.
//

import Foundation
import SwiftUI

public struct APIErrorView: View {

  public init(error: Error) {
    self.error = error
  }

  let error: Error

  public var body: some View {
    // TODO: Don't show description on RELEASE
    ContentUnavailableView(
      "Algo de errado aconteceu",
      systemImage: "xmark.octagon",
      description: Text((error as? APIError)?.jsonString ?? ""))
    .onAppear {
      dump(error as? APIError)
    }
  }
}
