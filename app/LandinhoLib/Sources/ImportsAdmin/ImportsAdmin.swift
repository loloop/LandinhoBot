import APIClient
import ComposableArchitecture
import Foundation

public struct ImportSettings: Codable, Equatable {
  let categoryTag: String
  let provider: String?
  let enabled: Bool
  let intervalDays: Int
  let lastImportAt: Date?
  let nextImportAt: Date?
}

public struct ImportHistory: Codable, Equatable {
  let items: [ScheduleImport]
  let metadata: Metadata
  struct Metadata: Codable, Equatable { let page: Int; let per: Int; let total: Int }
}

public struct ScheduleImport: Codable, Equatable, Identifiable {
  public let id: UUID
  let categoryTag: String
  let provider: String
  let trigger: String
  let startedAt: Date
  let finishedAt: Date?
  let status: String
  let changes: [Change]
  let issues: [Issue]

  var statusLabel: String {
    ["completed": "Concluída", "partial": "Com avisos", "failed": "Falhou", "running": "Em andamento"][status] ?? status
  }
  struct Change: Codable, Equatable {
    let title: String
    let field: String
    let before: String?
    let after: String?
    let sourceURL: String?
    var fieldLabel: String {
      ["meeting": "Etapa", "session": "Sessão", "date": "Horário", "scheduledDay": "Dia da sessão", "startDate": "Início", "endDate": "Fim", "title": "Título", "shortTitle": "Nome curto", "isCancelled": "Cancelamento", "isMainEvent": "Evento principal"][field] ?? field
    }
  }
  struct Issue: Codable, Equatable {
    let title: String
    let message: String
    let sourceURL: String?
    let candidates: [Candidate]
  }
  struct Candidate: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
  }
}

@Reducer
public struct ImportsAdmin {
  public init() {}
  public struct State: Equatable {
    public init(tag: String, title: String) { self.tag = tag; self.title = title }
    let tag: String
    let title: String
    @BindingState var enabled = true
    @BindingState var intervalDays = 7
    var settings = APIClient<ImportSettings>.State(endpoint: "import-settings")
    var history = APIClient<ImportHistory>.State(endpoint: "imports")
    var refresh = APIClient<ScheduleImport>.State(endpoint: "import-refresh")
    var match = APIClient<ImportSettings>.State(endpoint: "import-match")
    var runs: [ScheduleImport] = []
    var page = 1
    var canLoadMore = false
  }
  public enum Action: Equatable, BindableAction {
    case onAppear, saveSettings, refreshNow, loadMore
    case resolveMatch(UUID, Int, UUID)
    case binding(BindingAction<State>)
    case settings(APIClient<ImportSettings>.Action)
    case history(APIClient<ImportHistory>.Action)
    case refresh(APIClient<ScheduleImport>.Action)
    case match(APIClient<ImportSettings>.Action)
  }
  struct SettingsInput: Encodable { let categoryTag: String; let enabled: Bool; let intervalDays: Int }
  struct RefreshInput: Encodable { let categoryTag: String }
  struct MatchInput: Encodable { let runID: UUID; let issueIndex: Int; let recordID: UUID }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.page = 1
        return .merge(
          .send(.settings(.request(.get(["category": state.tag])))),
          .send(.history(.request(.get(["category": state.tag, "page": "1", "per": "25"])))))
      case .saveSettings:
        let input = SettingsInput(categoryTag: state.tag, enabled: state.enabled, intervalDays: state.intervalDays)
        return .run { send in try await send(.settings(.request(.patch(input)))) }
      case .refreshNow:
        let input = RefreshInput(categoryTag: state.tag)
        return .run { send in try await send(.refresh(.request(.post(input)))) }
      case .loadMore:
        return .send(.history(.request(.get(["category": state.tag, "page": String(state.page + 1), "per": "25"]))))
      case .resolveMatch(let runID, let index, let recordID):
        let input = MatchInput(runID: runID, issueIndex: index, recordID: recordID)
        return .run { send in try await send(.match(.request(.post(input)))) }
      case .settings(.response(.finished(.success(let settings)))):
        state.enabled = settings.enabled
        state.intervalDays = settings.intervalDays
        return .none
      case .history(.response(.finished(.success(let history)))):
        state.page = history.metadata.page
        if history.metadata.page == 1 { state.runs = history.items }
        else { state.runs.append(contentsOf: history.items) }
        state.canLoadMore = history.metadata.page * history.metadata.per < history.metadata.total
        return .none
      case .refresh(.response(.finished(.success))):
        return .send(.onAppear)
      case .match(.response(.finished(.success))):
        return .send(.refreshNow)
      case .settings, .history, .refresh, .match, .binding:
        return .none
      }
    }
    Scope(state: \.settings, action: \.settings) { APIClient() }
    Scope(state: \.history, action: \.history) { APIClient() }
    Scope(state: \.refresh, action: \.refresh) { APIClient() }
    Scope(state: \.match, action: \.match) { APIClient() }
  }
}
