//
//  VroomVroomApp.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import SwiftUI
import ComposableArchitecture
#if MOCK_NETWORKING
@_spi(Internal) import APIClient
@_spi(Internal) import MockAPIClient
#endif

@main
struct VroomVroomApp: App {

  let store = Store(initialState: Root.State()) {
    Root()
  } withDependencies: { dependencies in
    #if MOCK_NETWORKING
    dependencies.apiRequester = MockAPIClientService.liveValue
    #endif
  }

  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate

  init() {
    RacingScheduleShortcuts.updateAppShortcutParameters()
  }

  var body: some Scene {
    WindowGroup {
      RootView(store: store)
    }
  }
}
