//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct EventDetail: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {

  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {

      }
    }
  }
}

public struct EventDetailView: View {
  public init(store: StoreOf<EventDetail>) {
    self.store = store
  }

  let store: StoreOf<EventDetail>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Text("Placeholder")
    }
  }
}

