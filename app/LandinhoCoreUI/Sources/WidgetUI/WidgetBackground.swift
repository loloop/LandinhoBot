//
//  WidgetBackground.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

import Foundation
import SwiftUI

// The extensions contained in this file are for use in the main app. When using the widget views in a Widget Extension, you should use the proper Widget APIs.

public enum SupportedWidgetFamily {
  case systemSmall
  case systemMedium
  case systemLarge
}

public extension View {
  func widgetBackground() -> some View {
    self
      .padding()
      .background(Color(.systemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
      .shadow(color: .black.opacity(0.1), radius: 1)
  }

  func widgetFrame(family: SupportedWidgetFamily) -> some View {
    switch family {
    case .systemSmall:
      return self.frame(width: 170, height: 170)
    case .systemMedium:
      return self.frame(width: 364, height: 170)
    case .systemLarge:
      return self.frame(width: 364, height: 384)
    }
  }
}
