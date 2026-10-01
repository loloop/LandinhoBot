//
//  ShareableWidgetType.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

import Foundation

public enum ShareableWidgetType: Equatable, CaseIterable {
  case systemMedium
  case systemLarge

  var size: CGSize {
    switch self {
    case .systemMedium: CGSize(width: 364, height: 170)
    case .systemLarge: CGSize(width: 364, height: 384)
    }
  }
}
