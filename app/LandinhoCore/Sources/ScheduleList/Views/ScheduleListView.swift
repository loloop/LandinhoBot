import ComposableArchitecture
import Foundation
import LandinhoFoundation
import SwiftUI
import WidgetUI

public struct ScheduleListView: View {
  public init(store: StoreOf<ScheduleList>) { self.store = store }
  let store: StoreOf<ScheduleList>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        LazyVStack(spacing: 20) {
          if viewStore.hasLoaded, !viewStore.items.isEmpty {
            HStack {
              Text("\(viewStore.items.count) de \(viewStore.total) etapas")
                .font(.caption).foregroundStyle(.secondary)
              Spacer()
              if viewStore.isRefreshing { ProgressView().accessibilityLabel("Atualizando horários") }
            }
            .padding(.horizontal)
          }
          if !viewStore.hasLoaded, viewStore.isLoading {
            ProgressView("Carregando horários…").padding()
          }
          if viewStore.hasLoaded, viewStore.items.isEmpty {
            ContentUnavailableView("Nenhuma próxima etapa", systemImage: "flag.checkered",
              description: Text("Novos horários aparecerão aqui quando forem publicados."))
          }
          ForEach(viewStore.items) { item in
            VStack(alignment: .leading, spacing: 4) {
              if viewStore.favoriteTags.contains(item.category.tag) {
                Label("Favorita", systemImage: "heart.fill")
                  .font(.caption).foregroundStyle(.secondary)
              }
              Button {
                viewStore.send(.delegate(.onWidgetTap(item,
                  savedAt: viewStore.savedRoundIDs.contains(item.id) ? viewStore.lastUpdatedDate : nil)))
              } label: {
                NextRaceMediumWidgetView(race: item, lastUpdatedDate: viewStore.lastUpdatedDate)
                  .widgetBackground()
                  .widgetFrame(family: .systemMedium)
              }
              .buttonStyle(.plain)
              .contextMenu {
                Button("Compartilhar", systemImage: "square.and.arrow.up") {
                  viewStore.send(.delegate(.onShareTap(item)))
                }
              }
            }
          }
          if let message = viewStore.errorMessage {
            VStack(spacing: 12) {
              Text(message).multilineTextAlignment(.center)
              Button("Tentar novamente") { viewStore.send(.retry) }
            }
            .padding()
          } else if viewStore.canLoadMore {
            if viewStore.isLoading, !viewStore.isRefreshing {
              ProgressView("Carregando mais etapas…").padding()
            } else if !viewStore.isRefreshing {
              Button("Carregar mais etapas") { viewStore.send(.loadMore) }
                .padding()
            }
          }
        }
        .padding(.vertical)
      }
      .frame(maxWidth: .infinity)
      .background(.background.secondary)
      .refreshable { await viewStore.send(.refresh).finish() }
      .task { viewStore.send(.onAppear) }
      .onDisappear { viewStore.send(.onDisappear) }
    }
  }
}

#Preview {
  NavigationStack {
    ScheduleListView(store: Store(initialState: ScheduleList.State(categoryTag: nil)) { ScheduleList() })
      .navigationTitle("Home")
  }
}
