//
//  Categories.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct Categories: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {
    case onAppear
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        #warning("TODO call API")
        return .none
      }
    }
  }
}


public struct CategoriesView: View {
  public init() {}
  public var body: some View {
    VStack {
      Text("Placeholder for category list")
    }
    .padding()
  }
}

