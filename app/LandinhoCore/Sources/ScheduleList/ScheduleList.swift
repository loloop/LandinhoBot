@_spi(Internal) import APIClient
import CategoryFavorites
import CalendarStore
import ComposableArchitecture
import EventDetail
import Foundation
import LandinhoFoundation

public struct Page<T: Codable & Equatable & Identifiable>: Codable, Equatable {
  public let items: [T]
  public let metadata: Metadata
  public init(items: [T], metadata: Metadata) {
    self.items = items
    self.metadata = metadata
  }
  public struct Metadata: Codable, Equatable {
    public let page: Int
    public let per: Int
    public let total: Int
    public init(page: Int, per: Int, total: Int) {
      self.page = page
      self.per = per
      self.total = total
    }
  }
}

public struct ScheduleClient {
  public var page: (String?, Set<String>, Int, Int) async throws -> Page<Race>
  public init(page: @escaping (String?, Set<String>, Int, Int) async throws -> Page<Race>) {
    self.page = page
  }
}

extension ScheduleClient: DependencyKey {
  public static let liveValue = Self { category, favorites, page, per in
    @Dependency(\.apiRequester) var api
    var query = [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "per", value: String(per))]
    if let category { query.append(.init(name: "category", value: category)) }
    if category == nil, !favorites.isEmpty {
      query.append(.init(name: "favorites", value: favorites.sorted().joined(separator: ",")))
    }
    return try await api.request(Page<Race>.self, endpoint: "next-races", method: "GET", data: nil, queryItems: query, headers: [:])
  }
  public static let testValue = Self { _, _, _, _ in throw URLError(.unsupportedURL) }
}

public extension DependencyValues {
  var scheduleClient: ScheduleClient {
    get { self[ScheduleClient.self] }
    set { self[ScheduleClient.self] = newValue }
  }
}

public struct ScheduleList: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(categoryTag: String?, pageSize: Int = 5) {
      self.categoryTag = categoryTag
      self.pageSize = max(1, min(pageSize, 100))
    }
    public let categoryTag: String?
    public let pageSize: Int
    public var items: [Race] = []
    public var savedRoundIDs: Set<UUID> = []
    public var favoriteTags: Set<String> = []
    public var currentPage = 0
    public var total = 0
    public var hasLoaded = false
    public var inFlightPage: Int?
    public var isRefreshing = false
    public var errorMessage: String?
    public var failedPage: Int?
    public var lastUpdatedDate: Date?
    public var requestGeneration = 0
    var restoredPage: RestoredPage?
    struct RestoredPage: Equatable {
      let number: Int
      let startIndex: Int
    }

    public var canLoadMore: Bool { hasLoaded && currentPage * pageSize < total }
    public var isLoading: Bool { inFlightPage != nil }
  }

  public enum Action: Equatable {
    case onAppear
    case onDisappear
    case refresh
    case loadMore
    case retry
    case favoritesChanged(Set<String>)
    case pageResponse(generation: Int, page: Int, TaskResult<Page<Race>>)
    case savedPage(generation: Int, page: Int, SavedCalendar<CalendarPage>)
    case delegate(DelegateAction)
  }
  public enum DelegateAction: Equatable {
    case onWidgetTap(Race, savedAt: Date? = nil)
    case onShareTap(Race)
  }
  private enum CancelID { case page }
  @Dependency(\.scheduleClient) var client
  @Dependency(\.categoryFavorites) var favorites
  @Dependency(\.date.now) var now

  @Dependency(\.sessionReminders) var sessionReminders
  @Dependency(\.calendarStore) var calendarStore

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onDisappear:
        guard state.isLoading else { return .none }
        state.requestGeneration += 1
        state.inFlightPage = nil
        state.isRefreshing = false
        return .cancel(id: CancelID.page)

      case .onAppear:
        let tags = favorites.read()
        if state.hasLoaded || state.isLoading {
          guard state.categoryTag == nil, tags != state.favoriteTags else { return .none }
          return .send(.favoritesChanged(tags))
        }
        state.favoriteTags = tags
        return load(page: 1, state: &state)

      case .refresh:
        state.favoriteTags = favorites.read()
        return load(page: 1, state: &state)

      case .favoritesChanged(let tags):
        guard state.categoryTag == nil, state.favoriteTags != tags else { return .none }
        state.favoriteTags = tags
        state.items = []
        state.savedRoundIDs = []
        state.hasLoaded = false
        state.currentPage = 0
        state.total = 0
        return load(page: 1, state: &state)

      case .loadMore:
        guard state.canLoadMore, !state.isLoading else { return .none }
        return load(page: state.currentPage + 1, state: &state)

      case .retry:
        guard !state.isLoading else { return .none }
        return load(page: state.failedPage ?? 1, state: &state)

      case let .savedPage(generation, page, saved):
        guard generation == state.requestGeneration, page == state.inFlightPage,
          saved.value.page == page, saved.value.per == state.pageSize,
          !state.hasLoaded || page > state.currentPage else { return .none }
        if page == 1 {
          state.items = []
          state.savedRoundIDs = []
        }
        state.restoredPage = .init(number: page, startIndex: state.items.count)
        var ids = Set(state.items.map(\.id))
        let restored = saved.value.items.filter { !$0.isCancelled && ids.insert($0.id).inserted }
        state.items += restored
        state.savedRoundIDs.formUnion(restored.map(\.id))
        state.currentPage = page
        state.total = saved.value.total
        state.hasLoaded = true
        state.lastUpdatedDate = saved.updatedAt
        state.isRefreshing = page == 1
        return .none

      case let .pageResponse(generation, page, result):
        guard generation == state.requestGeneration, page == state.inFlightPage else { return .none }
        state.inFlightPage = nil
        state.isRefreshing = false
        switch result {
        case .success(let response):
          guard response.metadata.page == page, response.metadata.per == state.pageSize else {
            state.failedPage = page
            state.errorMessage = "A programação recebida está incompleta. Tente novamente."
            return .none
          }
          if page == 1 {
            state.items = []
            state.savedRoundIDs = []
          } else if let restored = state.restoredPage, restored.number == page {
            state.savedRoundIDs.subtract(state.items.dropFirst(restored.startIndex).map(\.id))
            state.items = Array(state.items.prefix(restored.startIndex))
          }
          state.restoredPage = nil
          var ids = Set(state.items.map(\.id))
          state.items += response.items.filter { !$0.isCancelled && ids.insert($0.id).inserted }
          state.savedRoundIDs.subtract(response.items.map(\.id))
          state.currentPage = page
          state.total = response.metadata.total
          state.hasLoaded = true
          state.lastUpdatedDate = now
          state.errorMessage = nil
          let query = CalendarQuery(category: state.categoryTag, favorites: state.favoriteTags, per: state.pageSize)
          let savedPage = CalendarPage(items: response.items, page: page, per: response.metadata.per,
            total: response.metadata.total)
          let updatedAt = now
          return .run { _ in
            // Storage failures must not hide a successfully fetched calendar.
            try? await calendarStore.savePage(query, savedPage, updatedAt)
            // Only reconcile the validated response, including cancelled rounds.
            _ = try await sessionReminders.refresh(response.items)
          } catch: { _, _ in
            // Leave schedule loading usable. Details read the actual pending state
            // and let the person request a reminder again if scheduling failed.
          }
        case .failure:
          state.failedPage = page
          state.errorMessage = "Não foi possível carregar os horários. Tente novamente."
        }
        return .none

      case .delegate:
        return .none
      }
    }
  }

  private func load(page: Int, state: inout State) -> Effect<Action> {
    state.requestGeneration += 1
    let generation = state.requestGeneration
    let category = state.categoryTag
    let tags = state.favoriteTags
    let per = state.pageSize
    let shouldRestore = !state.hasLoaded || page > state.currentPage
    let query = CalendarQuery(category: category, favorites: tags, per: per)
    state.inFlightPage = page
    state.isRefreshing = page == 1 && state.hasLoaded
    state.errorMessage = nil
    state.failedPage = nil
    return .run { send in
      if shouldRestore, let saved = try? await calendarStore.loadPage(query, page) {
        try Task.checkCancellation()
        await send(.savedPage(generation: generation, page: page, saved))
      }
      let result = await TaskResult { try await client.page(category, tags, page, per) }
      await send(.pageResponse(generation: generation, page: page, result))
    }
    .cancellable(id: CancelID.page, cancelInFlight: true)
  }
}
