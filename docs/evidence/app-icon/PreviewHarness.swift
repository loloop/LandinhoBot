import SwiftUI
import ComposableArchitecture
import LandinhoFoundation
import Sharing

// Evidence only: launches the real SharingView with fixed sample data.
@main
struct VroomVroomApp: App {
  let store: StoreOf<Sharing> = {
    let race = Race(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      title: "Grande Prêmio de São Paulo", shortTitle: "São Paulo",
      events: [
        RaceEvent(id: UUID(), title: "Treino Livre 1", date: Date(timeIntervalSince1970: 1793975400), isMainEvent: false),
        RaceEvent(id: UUID(), title: "Classificação", date: Date(timeIntervalSince1970: 1794065400), isMainEvent: false),
        RaceEvent(id: UUID(), title: "Corrida", date: Date(timeIntervalSince1970: 1794142800), isMainEvent: true)
      ], category: RaceCategory(id: "f1", title: "Fórmula 1", tag: "f1"))
    return Store(initialState: Sharing.State(race: race)) { Sharing() }
  }()

  var body: some Scene {
    WindowGroup {
      SharingView(store: store)
        .preferredColorScheme(ProcessInfo.processInfo.environment["LANDINHO_ICON_DARK"] == "1" ? .dark : .light)
    }
  }
}
