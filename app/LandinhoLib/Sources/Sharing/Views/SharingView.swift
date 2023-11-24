//
//  SharingView.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

@_spi(Mock) import Common
import ComposableArchitecture
import Foundation
import SwiftUI
import NotificationsQueue

public struct SharingView: View {

  public init(store: StoreOf<Sharing>) {
    self.store = store
  }

  let store: StoreOf<Sharing>

  @Environment(\.dismiss) var dismiss
  @Environment(\.displayScale) var displayScale

  public var body: some View {
    // TODO: Fix issue where title flickers when going backwards on the navigation stack
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        Color.black
          .ignoresSafeArea()

        SharingRenderableView(store: store)
          .frame(height: viewStore.isSquareAspectRatio ? 360 : 640)

        dismissButton(viewStore)
        cropButton(viewStore)
        shareButton(viewStore)
      }
      .sheet(isPresented: viewStore.$isSharing, onDismiss: {
        withAnimation {
          _ = viewStore.send(.onDismissShare)
        }
      }) {
        ActivityView(activityItems: [
          viewStore.renderedImage as Any
        ])
      }
      .toolbar(.hidden, for: .tabBar)
      .toolbar(.hidden, for: .navigationBar)
    }
  }

  @Dependency(\.notificationQueue) var notificationQueue

  @MainActor
  func dismissButton(_ viewStore: ViewStoreOf<Sharing>) -> some View {
    Button(action: {
      // TODO: This could be an easter egg feature dependency thing!
      let defaults = UserDefaults.standard
      let key = "me.mauriciocardozo.chevron.right"
      defaults.register(defaults: [key: false])
      if !defaults.bool(forKey: key) {
        notificationQueue.enqueue(.success("Ficou meio android né?"))
        defaults.setValue(true, forKey: key)
      }
      dismiss()
    }, label: {
      Image(systemName: "chevron.left")
        .bold()
    })
    .frame(width: 50, height: 50)
    .contentShape(Rectangle())
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    .opacity(viewStore.hasTappedShare ? 0 : 1)
  }

  @MainActor
  func shareButton(_ viewStore: ViewStoreOf<Sharing>) -> some View {
    Button(action: {
      withAnimation(.interpolatingSpring) {
        _ = viewStore.send(.onShareTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          render(isSquareAspectRatio: viewStore.isSquareAspectRatio)
        }
      }
    }, label: {
      if viewStore.hasTappedShare {
        ProgressView()
          .tint(.white)
          .padding(10)
      } else {
        Text("Compartilhar")
          .foregroundStyle(.white)
          .font(.caption)
          .padding(12)
          .padding(.horizontal, 5)
      }
    })
    .foregroundStyle(.white)
    .background(.black)
    .overlay {
      RoundedRectangle(cornerRadius: 25.0, style: .continuous)
        .stroke(.white, lineWidth: 1)
    }
    .frame(maxHeight: .infinity, alignment: .bottom)
  }

  @MainActor
  func cropButton(_ viewStore: ViewStoreOf<Sharing>) -> some View {
    Button(action: {
      withAnimation {
        _ = viewStore.send(.toggleAspectRatio)
      }
    }, label: {
      Image(systemName: "crop")
        .bold()
    })
    .frame(width: 50, height: 50)
    .contentShape(Rectangle())
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    .opacity(viewStore.hasTappedShare ? 0 : 1)
  }

  @MainActor
  func render(isSquareAspectRatio: Bool) {
    let renderer = ImageRenderer(content: SharingRenderableView(store: store))
    if isSquareAspectRatio {
      renderer.proposedSize.height = 360
      renderer.proposedSize.width = 360
    } else {
      renderer.proposedSize.height = 640
      renderer.proposedSize.width = 360
    }
    renderer.scale = displayScale
    if let image = renderer.uiImage {
      store.send(.onRender(image))
    }
  }
}

#Preview {
  SharingView(store: .init(initialState: .init(race: .mock), reducer: {
    Sharing()
  }))
}

private struct ActivityView: UIViewControllerRepresentable {
  var activityItems: [Any]
  var applicationActivities: [UIActivity]? = nil

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: applicationActivities)
    return controller
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context) {}
}

