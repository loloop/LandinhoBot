// Evidence-only native app. This file is never added to a shipping app target.
import LandinhoFoundation
import SwiftUI
import UIKit

@main
struct TextSharingEvidenceApp: App {
  init() {
    NSTimeZone.default = TimeZone(identifier: "America/Sao_Paulo")!
  }

  var body: some Scene {
    WindowGroup {
      TextSharingEvidenceView()
        .preferredColorScheme(.light)
    }
  }
}

private struct TextSharingEvidenceView: View {
  private let scenario = ProcessInfo.processInfo.arguments.last ?? "options"
  @State private var showingSheet = false

  private var race: Race {
    let base = Self.fixture
    let events: [RaceEvent]
    switch scenario {
    case "pending":
      events = [Self.session("Classificação", day: "2026-10-17"), Self.session("Corrida", isMain: true)]
    case "empty": events = []
    default: events = base.events
    }
    return Race(id: base.id, title: base.title, shortTitle: base.shortTitle, events: events,
      category: base.category, isCancelled: scenario == "cancelled")
  }

  private var payload: String {
    #if BEFORE
    race.roundLinkShareText
    #else
    RoundScheduleText.format(race: race)
    #endif
  }

  var body: some View {
    NavigationStack {
      if scenario == "options" {
        List {
          Section {
            Text(race.category.title).font(.headline)
            Text(race.title)
          }
          Section("Ações de compartilhamento") {
            // Exact production action views, displayed as a List because native
            // tap automation is unavailable. This is not an expanded Menu capture.
            RoundShareActions(race: race, onShareImage: {})
          }
          Section {
            Text("Prévia nativa do conteúdo do menu")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .navigationTitle(race.shortTitle)
      } else {
        ScrollView {
          Text(payload)
            .font(.body)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Texto da etapa")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSheet) {
          // The actual production formatter's String goes directly to the native
          // system share sheet. No destination is selected and nothing is sent.
          NativeTextShareSheet(text: payload)
        }
        .task {
          guard scenario == "sheet" else { return }
          try? await Task.sleep(for: .milliseconds(600))
          showingSheet = true
        }
      }
    }
  }

  private static let fixture = Race(
    id: UUID(uuidString: "4caebfb4-c669-46f1-b74e-ad391517f373")!,
    title: "Grande Prêmio de São Paulo",
    shortTitle: "São Paulo",
    events: [
      session("Corrida", date: "2026-10-18T17:00:00Z", isMain: true),
      session("Treino Livre", date: "2026-10-16T13:00:00Z"),
      session("Classificação", day: "2026-10-17"),
      session("Sprint", date: "2026-10-17T15:00:00Z", isCancelled: true)
    ],
    category: .init(id: "f1", title: "Formula 1", tag: "f1"))

  private static func session(_ title: String, date: String? = nil, day: String? = nil,
                              isMain: Bool = false, isCancelled: Bool = false) -> RaceEvent {
    RaceEvent(id: UUID(), title: title, date: date.flatMap { ISO8601DateFormatter().date(from: $0) },
      isMainEvent: isMain, isCancelled: isCancelled, scheduledDay: day)
  }
}

private struct NativeTextShareSheet: UIViewControllerRepresentable {
  let text: String

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [text], applicationActivities: nil)
  }

  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
