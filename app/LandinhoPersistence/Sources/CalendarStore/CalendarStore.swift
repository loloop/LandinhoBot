import Dependencies
import Foundation
import LandinhoFoundation

public struct SavedCalendar<Value: Equatable>: Equatable {
  public let value: Value
  public let updatedAt: Date
  public init(value: Value, updatedAt: Date) {
    self.value = value
    self.updatedAt = updatedAt
  }
}

/// Favorites affect the Home order, but never a category's own schedule.
public struct CalendarQuery: Codable, Equatable {
  public let category: String?
  public let favorites: [String]
  public let per: Int
  public init(category: String?, favorites: Set<String>, per: Int) {
    self.category = category
    self.favorites = category == nil ? favorites.sorted() : []
    self.per = per
  }
}

public struct CalendarPage: Equatable {
  public let items: [Race]
  public let page: Int
  public let per: Int
  public let total: Int
  public init(items: [Race], page: Int, per: Int, total: Int) {
    self.items = items
    self.page = page
    self.per = per
    self.total = total
  }
}

/// Public calendar data only. Credentials and administrative responses never enter this store.
public struct CalendarStore {
  public var loadCategories: () async throws -> SavedCalendar<[RaceCategory]>?
  public var saveCategories: ([RaceCategory], Date) async throws -> Void
  public var loadPage: (CalendarQuery, Int) async throws -> SavedCalendar<CalendarPage>?
  public var savePage: (CalendarQuery, CalendarPage, Date) async throws -> Void
  public var loadRound: (UUID) async throws -> SavedCalendar<Race>?
  public var saveRound: (Race, Date) async throws -> Void
  public var removeRound: (UUID) async throws -> Void

  public init(
    loadCategories: @escaping () async throws -> SavedCalendar<[RaceCategory]>? = { nil },
    saveCategories: @escaping ([RaceCategory], Date) async throws -> Void = { _, _ in },
    loadPage: @escaping (CalendarQuery, Int) async throws -> SavedCalendar<CalendarPage>? = { _, _ in nil },
    savePage: @escaping (CalendarQuery, CalendarPage, Date) async throws -> Void = { _, _, _ in },
    loadRound: @escaping (UUID) async throws -> SavedCalendar<Race>? = { _ in nil },
    saveRound: @escaping (Race, Date) async throws -> Void = { _, _ in },
    removeRound: @escaping (UUID) async throws -> Void = { _ in }
  ) {
    self.loadCategories = loadCategories
    self.saveCategories = saveCategories
    self.loadPage = loadPage
    self.savePage = savePage
    self.loadRound = loadRound
    self.saveRound = saveRound
    self.removeRound = removeRound
  }

  /// A nil URL creates an isolated in-memory SQLite database for tests and the mock app.
  public init(databaseURL: URL?, source: String = "https://api.vroomvroom.racing") {
    let database = CalendarDatabase(url: databaseURL, source: source)
    self.init(
      loadCategories: { try await database.loadCategories() },
      saveCategories: { try await database.saveCategories($0, updatedAt: $1) },
      loadPage: { try await database.loadPage($0, page: $1) },
      savePage: { try await database.savePage($1, query: $0, updatedAt: $2) },
      loadRound: { try await database.loadRound($0) },
      saveRound: { try await database.saveRound($0, updatedAt: $1) },
      removeRound: { try await database.removeRound($0) })
  }
}

extension CalendarStore: DependencyKey {
  public static let liveValue = Self(
    databaseURL: URL.applicationSupportDirectory.appending(path: "Landinho/calendar.sqlite"),
    source: ProcessInfo.processInfo.environment["LANDINHO_API_URL"] ?? "https://api.vroomvroom.racing")
  public static let testValue = Self()
  public static let previewValue = Self()
}

public extension DependencyValues {
  var calendarStore: CalendarStore {
    get { self[CalendarStore.self] }
    set { self[CalendarStore.self] = newValue }
  }
}
