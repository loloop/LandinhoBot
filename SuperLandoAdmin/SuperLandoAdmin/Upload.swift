//
//  Upload.swift
//  SuperLandoAdmin
//
//  Created by Mauricio Cardozo on 25/09/23.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import AdminLib

struct Upload: Reducer {

  struct State: Equatable {
    var uploadCategoryState = UploadCategory.State()
    var uploadRaceState = UploadRace.State()
  }

  enum Action: Equatable {
    case uploadCategory(UploadCategory.Action)
    case uploadRace(UploadRace.Action)
  }

  var body: some ReducerOf<Upload> {
    Scope(state: \.uploadCategoryState, action: /Action.uploadCategory) {
      UploadCategory()
    }

    Scope(state: \.uploadRaceState, action: /Action.uploadRace) {
      UploadRace()
    }
  }
}

struct UploadView: View {
  let store: StoreOf<Upload>

  var body: some View {
    Form {
      UploadCategoryView(
        store: store.scope(
          state: \.uploadCategoryState,
          action: Upload.Action.uploadCategory))

      UploadRaceView(
        store: store.scope(
          state: \.uploadRaceState,
          action: Upload.Action.uploadRace))
    }
  }
}

