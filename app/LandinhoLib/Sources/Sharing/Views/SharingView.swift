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

        dismissButton(viewStore)

        SharingRenderableView(store: store)
          .frame(height: viewStore.isSquareAspectRatio ? 360 : 640)

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

  @MainActor
  func dismissButton(_ viewStore: ViewStoreOf<Sharing>) -> some View {
    Button(action: {
      dismiss()
    }, label: {
      Image(systemName: "chevron.left")
        .bold()
    })
    .frame(width: 50, height: 50)
    .contentShape(Rectangle())
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

#Preview("Instagram Ratio") {
  NavigationStack {
    NavigationLink {
      SharingView(store: .init(initialState: .init(race: .mock, isSquareAspectRatio: false), reducer: {
        Sharing()
      }))
    } label: {
      Text("push")
    }
    .navigationTitle("push")
    .navigationBarTitleDisplayMode(.large)
  }
}

#Preview("Square Ratio") {
  SharingView(store: .init(initialState: .init(race: .mock, isSquareAspectRatio: true), reducer: {
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
