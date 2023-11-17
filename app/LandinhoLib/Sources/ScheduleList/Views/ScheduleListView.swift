//
//  ScheduleListView.swift
//
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import APIClient
import Common
import ComposableArchitecture
import Foundation
import SwiftUI
import WidgetUI

public struct ScheduleListView: View {
  public init(store: StoreOf<ScheduleList>) {
    self.store = store
  }

  let store: StoreOf<ScheduleList>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
        switch viewStore.racesState.response {
        case .idle:
          Color(.systemBackground)
          .task {
            viewStore.send(.onAppear)
          }
        case .loading:
          ProgressView()
        case .reloading(let response), .finished(.success(let response)):
          ScrollView {
            VStack(spacing: 20) {
              Text("Ainda não tem nada por aqui, mas se você quiser ver, esse são os Widgets do app por enquanto:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
              ScrollView(.horizontal) {
                HStack {
                  Spacer().padding(.leading, 5)
                  ForEach(response.items) { item in
                    smallWidget(for: item)
                      .onTapAnimate {
                        viewStore.send(.delegate(.onWidgetTap(item)))
                      }
                  }
                  Spacer().padding(.trailing, 5)
                }
              }
              .scrollClipDisabled()
              .scrollIndicators(.hidden)

              ScrollView(.horizontal) {
                HStack {
                  Spacer().padding(.leading, 5)
                  ForEach(response.items) { item in
                    NextRaceMediumWidgetView(bundle: item.bundled, lastUpdatedDate: Date())
                      .padding()
                      .background(Color(.systemBackground))
                      .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
                      .frame(width: 364, height: 170)
                      .shadow(color: .black.opacity(0.1), radius: 1)
                      .onTapAnimate {
                        viewStore.send(.delegate(.onWidgetTap(item)))
                      }
                  }
                  Spacer().padding(.trailing, 5)
                }
              }
              .scrollClipDisabled()
              .scrollIndicators(.hidden)

              ScrollView(.horizontal) {
                HStack {
                  Spacer().padding(.leading, 5)
                  ForEach(response.items) { item in
                    NextRaceLargeWidgetView(bundle: item.bundled, lastUpdatedDate: Date())
                      .padding()
                      .background(Color(.systemBackground))
                      .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
                      .frame(width: 364, height: 384)
                      .shadow(color: .black.opacity(0.1), radius: 1)
                      .onTapAnimate {
                        viewStore.send(.delegate(.onWidgetTap(item)))
                      }
                  }
                  Spacer().padding(.trailing, 5)
                }
              }
              .scrollClipDisabled()
              .scrollIndicators(.hidden)

              Spacer().frame(height: 50)
            }
          }
          .background(
            .background.secondary
          )
          .refreshable {
            viewStore.send(.onAppear)
          }
        case .finished(.failure(let error)):
          APIErrorView(error: error)
        }
    }
  }

  @MainActor
  func smallWidget(for bundle: MegaRace) -> some View {
    NextRaceSmallWidgetView(bundle: bundle.bundled, lastUpdatedDate: Date())
      .padding()
      .background(Color(.systemBackground))
      .frame(width: 170, height: 170)
      .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
      .shadow(color: .black.opacity(0.1), radius: 1)
  }
}

#Preview {
  let store = Store(initialState: ScheduleList.State(categoryTag: nil)) {
    ScheduleList()
  }
  store.send(.racesRequest(.response(.finished(.success(.init(items: [
    .init(
      id: .init(),
      title: "Race",
      shortTitle: "Race",
      events: [
        .init(
          id: .init(),
          title: "Treino Livre 1",
          date: Date(),
          isMainEvent: false)
      ],
      category: .init(
        id: .init(),
        title: "Formula 1",
        tag: "f1"))
  ], metadata: .init(page: 0, per: 0, total: 0)))))))

  return NavigationStack {
    ScheduleListView(store: store)
    .navigationTitle("ScheduleList")
  }
}

// TODO: Move to a new module, CommonUI or whatever
struct TapAnimationModifier: ViewModifier {
    @State private var isTapped = false
    var completion: () -> Void
    var animation: Animation = .default
    var delay: TimeInterval = 0.2  // Default dela

    func body(content: Content) -> some View {
        content
        .scaleEffect(isTapped ? 0.95 : 1.0)
        .onTapGesture {
          withAnimation(.spring(duration: delay)) {
            isTapped = true
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            completion()
            withAnimation(.spring(duration: 0.1)) {
              isTapped = false
            }
          }
      }
    }
}

extension View {
    func onTapAnimate(animation: Animation = .default, delay: TimeInterval = 0.5, completion: @escaping () -> Void) -> some View {
        self.modifier(TapAnimationModifier(completion: completion, animation: animation, delay: delay))
    }
}
