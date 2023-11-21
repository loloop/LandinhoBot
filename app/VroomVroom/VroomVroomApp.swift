//
//  VroomVroomApp.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct VroomVroomApp: App {

  let store = Store(initialState: Root.State()) {
    Root()
  }

  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate

  var body: some Scene {
    WindowGroup {
      RootView(store: store)
    }
  }
}
