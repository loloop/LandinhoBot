//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import ComposableArchitecture
import Foundation
import SwiftUI

public struct ScheduleItem: View {
  public init(store: StoreOf<ScheduleList>) {
    self.store = store
  }

  let store: StoreOf<ScheduleList>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Text("Placeholder")
    }
  }
}

