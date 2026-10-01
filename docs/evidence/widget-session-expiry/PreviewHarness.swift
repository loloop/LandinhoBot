import Foundation
import SwiftUI
import LandinhoFoundation
import WidgetUI

// Native simulator evidence for the production widget views, not SpringBoard hosting.
@main
struct WidgetEvidenceApp: App {
  init() {
    NSTimeZone.default = TimeZone(identifier: "America/Sao_Paulo")!
  }

  var body: some Scene {
    WindowGroup {
      EvidenceView()
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .preferredColorScheme(.light)
    }
  }
}

struct EvidenceView: View {
  let state = ProcessInfo.processInfo.arguments.last ?? "upcoming"
  let base = ISO8601DateFormatter().date(from: "2026-10-02T13:00:00-03:00")!

  var reference: Date {
    switch state {
    case "qualifying": return base.addingTimeInterval(60 * 60)
    case "completed", "large-completed": return base.addingTimeInterval(4 * 60 * 60)
    case "filters": return base.addingTimeInterval(-4 * 60 * 60)
    default: return base
    }
  }

  var round: Race {
    var events: [RaceEvent] = [
      .init(id: UUID(), title: "Treino livre", date: base.addingTimeInterval(-3 * 60 * 60), isMainEvent: false),
      .init(id: UUID(), title: "Classificação", date: base.addingTimeInterval(60 * 60), isMainEvent: false),
      .init(id: UUID(), title: "Corrida", date: base.addingTimeInterval(4 * 60 * 60), isMainEvent: true)
    ]
    if state == "pending" {
      events.append(.init(id: UUID(), title: "Sprint", date: nil, isMainEvent: true, scheduledDay: "2026-10-03"))
      events.append(.init(id: UUID(), title: "Treino cancelado", date: base.addingTimeInterval(2 * 60 * 60), isMainEvent: false, isCancelled: true))
    }
    return Race(id: UUID(), title: "Grande Prêmio de São Paulo", shortTitle: "São Paulo",
                events: events, category: .init(id: "f1", title: "Formula 1", tag: "f1"),
                isCancelled: state == "cancelled")
  }

  var body: some View {
    VStack(spacing: 12) {
      Text("Widgets · \(reference.formatted(date: .omitted, time: .shortened))")
        .font(.title2.bold())
      Text("SwiftUI nativo · referência fixa · \(state)")
        .font(.caption).foregroundStyle(.secondary)
      if state.hasPrefix("large") {
        large
      } else if state == "filters" {
        HStack(alignment: .top, spacing: 12) {
          VStack {
            Text("Com treinos").font(.caption)
            small(showNonMain: true)
          }
          VStack {
            Text("Só principais").font(.caption)
            small(showNonMain: false)
          }
        }
        medium
      } else {
        medium
        HStack {
          small(showNonMain: true)
          Text("Pequeno\nPróxima sessão")
            .font(.caption).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
        .frame(width: 364)
      }
    }
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGroupedBackground))
  }

  var medium: some View {
    #if BEFORE
    NextRaceMediumWidgetView(race: round, lastUpdatedDate: base)
      .widgetBackground().widgetFrame(family: .systemMedium)
    #else
    NextRaceMediumWidgetView(race: round, lastUpdatedDate: base, referenceDate: reference)
      .widgetBackground().widgetFrame(family: .systemMedium)
    #endif
  }

  var large: some View {
    #if BEFORE
    NextRaceLargeWidgetView(race: round, lastUpdatedDate: base)
      .widgetBackground().widgetFrame(family: .systemLarge)
    #else
    NextRaceLargeWidgetView(race: round, lastUpdatedDate: base, referenceDate: reference)
      .widgetBackground().widgetFrame(family: .systemLarge)
    #endif
  }

  func small(showNonMain: Bool) -> some View {
    #if BEFORE
    NextRaceSmallWidgetView(race: round, lastUpdatedDate: base)
      .widgetBackground().widgetFrame(family: .systemSmall)
    #else
    NextRaceSmallWidgetView(race: round, lastUpdatedDate: base, referenceDate: reference, showNonMainEventSessions: showNonMain)
      .widgetBackground().widgetFrame(family: .systemSmall)
    #endif
  }
}
