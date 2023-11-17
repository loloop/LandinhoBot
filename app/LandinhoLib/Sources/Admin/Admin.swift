//
//  Admin.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import ComposableArchitecture
import Foundation
import CategoriesAdmin

// This layer is reserved for future use

public struct Admin: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var categoriesAdminState = CategoriesAdmin.State()
  }

  public enum Action: Equatable {
    case categoriesAdmin(CategoriesAdmin.Action)
  }

  public var body: some ReducerOf<Self> {
    Scope(state: \.categoriesAdminState, action: /Action.categoriesAdmin) {
      CategoriesAdmin()
    }
  }
}

import SwiftUI

public struct AdminView: View {
  public init(store: StoreOf<Admin>) {
    self.store = store
  }

  let store: StoreOf<Admin>

  public var body: some View {
    CategoriesAdminView(store: store.scope(
      state: \.categoriesAdminState,
      action: Admin.Action.categoriesAdmin))
  }
}
