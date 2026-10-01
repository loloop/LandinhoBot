// Reproduction-only app entry. capture.sh temporarily replaces the app entry;
// this file is never compiled into the shipping app.
import ComposableArchitecture
import Categories
import CategoryFavorites
import EventDetail
import LandinhoFoundation
import ScheduleList
import Sharing
import SwiftUI
import WidgetUI

@main
struct CategoryAccentEvidenceApp: App {
  static let arguments = ProcessInfo.processInfo.arguments
  static let referenceDate = ISO8601DateFormatter().date(from: "2026-11-06T12:00:00Z")!
  static let categories: [RaceCategory] = [
    .init(id: "white", title: "Formula 1", tag: "f1", color: .init(hex: "#FFFFFF")),
    .init(id: "black", title: "Stock Car Brasil", tag: "stock-car", color: .init(hex: "#000000")),
    .init(id: "yellow", title: "Formula E", tag: "formula-e", color: .init(hex: "#FFFF00")),
    .init(id: "red", title: "IndyCar", tag: "indycar", color: .init(hex: "#E34B43")),
  ]
  static let rounds = categories.map { category in
    Race(
      id: UUID(), title: "Etapa de São Paulo", shortTitle: "São Paulo",
      events: [
        .init(id: UUID(), title: "Classificação", date: referenceDate.addingTimeInterval(3600), isMainEvent: false),
        .init(id: UUID(), title: "Corrida", date: referenceDate.addingTimeInterval(90000), isMainEvent: true),
      ], category: category, sourceURL: "https://www.fia.com")
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if Self.arguments.contains("categories") {
          NavigationStack {
            CategoriesView(store: Store(initialState: Self.categoriesState) {
              Categories()
            } withDependencies: {
              $0.categoryFavorites = .init(read: { ["f1", "stock-car", "indycar"] }, write: { _ in })
            })
              .navigationTitle("Categorias")
          }
        } else if Self.arguments.contains("detail") {
          NavigationStack {
            EventDetailView(store: Store(initialState: EventDetail.State(race: Self.rounds[2])) { EventDetail() })
          }
        } else if Self.arguments.contains("sharing") {
          SharingView(store: Store(initialState: Sharing.State(race: Self.rounds[3])) { Sharing() })
        } else if Self.arguments.contains("widgets") {
          ScrollView {
            VStack(spacing: 20) {
              HStack {
                NextRaceSmallWidgetView(race: Self.rounds[0], lastUpdatedDate: Self.referenceDate)
                  .widgetBackground().widgetFrame(family: .systemSmall)
                NextRaceSmallWidgetView(race: Self.rounds[1], lastUpdatedDate: Self.referenceDate)
                  .widgetBackground().widgetFrame(family: .systemSmall)
              }
              NextRaceLargeWidgetView(race: Self.rounds[2], lastUpdatedDate: Self.referenceDate)
                .widgetBackground().widgetFrame(family: .systemLarge)
            }
            .padding(.vertical)
          }
          .frame(maxWidth: .infinity)
          .background(.background.secondary)
        } else {
          NavigationStack {
            ScheduleListView(store: Store(initialState: Self.scheduleState) {
              ScheduleList()
            } withDependencies: {
              $0.categoryFavorites = .init(read: { [] }, write: { _ in })
            })
              .navigationTitle("Programação")
          }
        }
      }
      .preferredColorScheme(Self.arguments.contains("dark") ? .dark : .light)
    }
  }

  static var scheduleState: ScheduleList.State {
    var state = ScheduleList.State(categoryTag: nil)
    state.items = Array(rounds.prefix(3))
    state.total = state.items.count
    state.currentPage = 1
    state.hasLoaded = true
    state.lastUpdatedDate = referenceDate
    return state
  }

  static var categoriesState: Categories.State {
    var state = Categories.State()
    state.favoriteTags = ["f1", "stock-car", "indycar"]
    state.categoriesState.response = .finished(.success(categories))
    return state
  }
}
