//
//  ShareableWidgetType.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

import Foundation
import WidgetUI

public enum ShareableWidgetType: Equatable, CaseIterable {
  case systemMedium
  case systemLarge

  var supportedFamily: SupportedWidgetFamily {
    switch self {
    case .systemMedium: .systemMedium
    case .systemLarge: .systemLarge
    }
  }
}
