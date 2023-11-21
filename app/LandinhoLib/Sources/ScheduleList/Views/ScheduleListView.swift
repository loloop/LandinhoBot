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
              VStack {
                Text("Ainda não tem nada por aqui, mas se você quiser ver, esse são os Widgets do app por enquanto:")
                  .frame(maxWidth: .infinity, alignment: .leading)
                Text("*Toca neles pra ir pra tela da corrida*")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              .padding(.horizontal)

              ScrollView(.horizontal) {
                HStack {
                  Spacer().padding(.leading, 5)
                  ForEach(response.items) { item in
                    NextRaceSmallWidgetView(bundle: item.bundled, lastUpdatedDate: Date())
                      .widgetBackground()
                      .widgetFrame(family: .systemSmall)
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
                      .widgetBackground()
                      .widgetFrame(family: .systemMedium)
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
                      .widgetBackground()
                      .widgetFrame(family: .systemLarge)
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
    var delay: TimeInterval = 0.2

    func body(content: Content) -> some View {
        content
        .scaleEffect(isTapped ? 0.95 : 1.0)
        .onTapGesture {
          withAnimation(.spring(duration: delay)) {
            isTapped = true
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            completion()
            withAnimation(.spring(duration: delay)) {
              isTapped = false
            }
          }
      }
    }
}

extension View {
    func onTapAnimate(delay: TimeInterval = 0.2, completion: @escaping () -> Void) -> some View {
        self.modifier(TapAnimationModifier(completion: completion, delay: delay))
    }
}
