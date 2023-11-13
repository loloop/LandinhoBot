//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct Settings: Reducer {
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

public struct SettingsView: View {
  public init() {}
  public var body: some View {
    NavigationStack {
      Form {
        Text("")
      }
    }
    .navigationTitle("Settings")
  }
}
