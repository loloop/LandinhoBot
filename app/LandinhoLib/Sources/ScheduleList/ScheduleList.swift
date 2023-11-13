//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct ScheduleList: Reducer {

  public init() {
    
  }

  public struct State: Equatable {
    public init(categoryTag: String?) {
      self.categoryTag = categoryTag
    }

    let categoryTag: String?
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

public struct ScheduleListView: View {
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

