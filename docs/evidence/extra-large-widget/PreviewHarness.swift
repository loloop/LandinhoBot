import Foundation
import LandinhoFoundation
import SwiftUI
import WidgetKit
import WidgetUI

// Production family switch and WidgetUI, hosted by a native iPad app.
// The harness injects the read-only WidgetKit family into the extracted dispatcher.
// This is not a SpringBoard widget-placement screenshot.
@main
struct ExtraLargeEvidenceApp: App {
  init() {
    NSTimeZone.default = TimeZone(identifier: "America/Sao_Paulo")!
  }

  var body: some Scene {
    WindowGroup {
      EvidenceView()
        .environment(\.locale, Locale(identifier: "pt_BR"))
    }
  }
}

struct EvidenceView: View {
  let scenario = ProcessInfo.processInfo.arguments.last ?? "standard"
  let base = ISO8601DateFormatter().date(from: "2026-10-02T09:00:00-03:00")!

  var round: Race {
    var events: [RaceEvent] = [
      .init(id: UUID(), title: "Treino livre 1", date: base.addingTimeInterval(-3600), isMainEvent: false),
      .init(id: UUID(), title: "Treino livre 2", date: base.addingTimeInterval(4 * 3600), isMainEvent: false),
      .init(id: UUID(), title: "Classificação Sprint", date: base.addingTimeInterval(7 * 3600), isMainEvent: false),
      .init(id: UUID(), title: "Sprint", date: base.addingTimeInterval(27 * 3600), isMainEvent: true),
      .init(id: UUID(), title: "Classificação", date: base.addingTimeInterval(31 * 3600), isMainEvent: false),
      .init(id: UUID(), title: "Corrida", date: base.addingTimeInterval(52 * 3600), isMainEvent: true)
    ]
    if scenario == "pending" {
      events.append(.init(id: UUID(), title: "Sessão com horário pendente", date: nil, isMainEvent: true, scheduledDay: "2026-10-04"))
      events.append(.init(id: UUID(), title: "Treino cancelado", date: base.addingTimeInterval(3600), isMainEvent: false, isCancelled: true))
    }
    if scenario == "dense" || scenario.contains("large-text") {
      events += (1...8).map { index in
        .init(id: UUID(), title: "Corrida complementar \(index)", date: base.addingTimeInterval(Double(index + 55) * 3600), isMainEvent: true)
      }
    }
    if scenario == "completed" { events = events.map { .init(id: $0.id, title: $0.title, date: base.addingTimeInterval(-60), isMainEvent: $0.isMainEvent) } }
    let title = scenario.hasPrefix("long-titles") ? "Grande Prêmio de São Paulo — etapa comemorativa do campeonato internacional" : "Grande Prêmio de São Paulo"
    if scenario.hasPrefix("long-titles") {
      events = events.map { .init(id: $0.id, title: "\($0.title) — programação oficial da etapa", date: $0.date, isMainEvent: $0.isMainEvent) }
    }
    return Race(id: UUID(), title: title, shortTitle: "São Paulo", events: events,
                category: .init(id: "f1", title: "Formula 1", tag: "f1"),
                sourceURL: "https://www.formula1.com/en/racing/2026", isCancelled: scenario == "cancelled")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Widget extra-largo · iPad")
        .font(.title.bold())
      Text("SwiftUI nativo · família systemExtraLarge · \(scenario)")
        .font(.subheadline).foregroundStyle(.secondary)
      NextRaceWidgetView(family: .systemExtraLarge, race: round, lastUpdatedDate: base, referenceDate: base,
                         showNonMainEventSessions: scenario != "filtered")
        .environment(\.dynamicTypeSize, scenario == "large-text-max" || scenario == "long-titles-large-text" ? .accessibility5 : scenario == "large-text-dark" ? .accessibility1 : .large)
        .padding(16)
        .frame(width: scenario == "wide" ? 800 : 720, height: scenario == "wide" ? 385 : 342)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26))
      Text("Vista de produção em um app temporário de evidência; não é a tela inicial do iPad.")
        .font(.caption).foregroundStyle(.secondary)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(Color(uiColor: .systemGroupedBackground))
    .preferredColorScheme(scenario.contains("large-text") ? .dark : .light)
  }
}
