import APIClient
import AppIntents
import LandinhoFoundation
import SwiftUI

struct RacingCategoryEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Categoria"
  static var defaultQuery = RacingCategoryQuery()

  let id: String
  let title: String
  let tag: String

  init(_ category: RaceCategory) {
    id = category.id
    title = category.title
    tag = category.tag
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(title)", subtitle: "\(tag)")
  }
}

struct RacingCategoryQuery: EntityStringQuery {
  func entities(for identifiers: [RacingCategoryEntity.ID]) async throws -> [RacingCategoryEntity] {
    try await load().filter { identifiers.contains($0.id) }
  }

  func entities(matching string: String) async throws -> [RacingCategoryEntity] {
    let search = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !search.isEmpty else { return try await suggestedEntities() }
    return try await load().filter {
      $0.title.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        || $0.tag.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
  }

  func suggestedEntities() async throws -> [RacingCategoryEntity] { try await load() }

  private func load() async throws -> [RacingCategoryEntity] {
    do { return try await SiriScheduleClient.categories().map(RacingCategoryEntity.init) }
    catch is CancellationError { throw CancellationError() }
    catch { throw SiriScheduleIntentError.unavailable }
  }
}

enum RacingSessionKind: String, AppEnum {
  case race
  case session

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tipo de sessão"
  static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .race: "Corrida",
    .session: "Sessão, incluindo treinos e classificação"
  ]
}

// Checked against Xcode 27.1 and Apple's current schemas:
// @AppIntent(schema:) is available from iOS 18, while calendar schemas are iOS 27.
// Calendar intents mutate events; system.searchInApp navigates to app search results.
// The calendar event entity also requires start and end dates, which our sources do
// not supply for pending times. A normal read-only AppIntent preserves iOS 17 and
// describes this answer without inventing a session end or claiming a search UI.
// https://developer.apple.com/documentation/appintents/app-schema-domain-calendar
// https://developer.apple.com/documentation/appintents/appschema/calendarentity/event
// https://developer.apple.com/documentation/appintents/appschema/systemintent/searchinapp
struct AskNextRacingSessionIntent: AppIntent {
  static var title: LocalizedStringResource = "Consultar próximo horário"
  static var description = IntentDescription("Consulta a próxima corrida ou sessão no calendário. Sem categoria, compara todas as categorias. Os horários confirmados usam o fuso do aparelho.")
  static var openAppWhenRun = false

  @Parameter(title: "Categoria")
  var category: RacingCategoryEntity?

  @Parameter(title: "Tipo de sessão", default: .race)
  var sessionKind: RacingSessionKind

  static var parameterSummary: some ParameterSummary {
    Summary("Consultar próxima \(\.$sessionKind)") {
      \.$category
    }
  }

  init() {}

  init(sessionKind: RacingSessionKind) { self.sessionKind = sessionKind }

  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
    let rounds: [Race]
    do { rounds = try await SiriScheduleClient.upcomingRounds(categoryTag: category?.tag) }
    catch is CancellationError { throw CancellationError() }
    catch { throw SiriScheduleIntentError.unavailable }

    let answer = UpcomingSessionQuery.answer(
      rounds: rounds, now: Date(), mainSessionsOnly: sessionKind == .race, categoryTag: category?.tag)
    let message = answer.message(categoryTitle: category?.title)
    return .result(value: message, dialog: IntentDialog(stringLiteral: message), view: RacingScheduleSnippet(answer: answer, message: message))
  }
}

enum SiriScheduleIntentError: LocalizedError {
  case unavailable

  var errorDescription: String? {
    "Não consegui consultar o calendário agora. Confira sua conexão e tente novamente."
  }
}

struct RacingScheduleShortcuts: AppShortcutsProvider {
  static var shortcutTileColor: ShortcutTileColor = .green

  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AskNextRacingSessionIntent(sessionKind: .race),
      phrases: [
        "Quando é a próxima corrida no \(.applicationName)",
        "Qual o horário da próxima corrida no \(.applicationName)",
        "Quando é a próxima corrida de \(\.$category) no \(.applicationName)"
      ],
      shortTitle: "Próxima corrida",
      systemImageName: "flag.checkered")
    AppShortcut(
      intent: AskNextRacingSessionIntent(sessionKind: .session),
      phrases: [
        "Quando é a próxima sessão no \(.applicationName)",
        "Quando é a próxima sessão de \(\.$category) no \(.applicationName)"
      ],
      shortTitle: "Próxima sessão",
      systemImageName: "clock")
  }
}

struct RacingScheduleSnippet: View {
  let answer: UpcomingSessionAnswer
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("VroomVroom", systemImage: "flag.checkered")
        .font(.headline)
      Text(message)
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
      if case .scheduled(_, let session) = answer, let date = session.date {
        Text(date, style: .relative)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .accessibilityElement(children: .combine)
  }
}
