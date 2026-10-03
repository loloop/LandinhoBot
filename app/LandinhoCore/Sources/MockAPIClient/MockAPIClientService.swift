@_spi(Internal) import APIClient
import CalendarStore
import ComposableArchitecture
import Foundation

/// An isolated, in-memory backend. Each instance starts with a fresh sample schedule.
@_spi(Internal) public actor MockAPIClientService: APIClientServiceProtocol {
  public static let liveValue = MockAPIClientService()

  public static func configure(_ dependencies: inout DependencyValues) {
    dependencies.apiRequester = liveValue
    dependencies.calendarStore = CalendarStore(databaseURL: nil, source: "mock")
  }

  private var categories: [[String: Any]]
  private var races: [[String: Any]]
  private var settings: [String: [String: Any]] = [:]
  private var imports: [[String: Any]] = []

  public init(now: Date = Date()) {
    let f1: [String: Any] = [
      "id": Self.id(1), "title": "Formula 1", "tag": "f1",
      "comment": "Calendário de demonstração"
    ]
    let stock: [String: Any] = [
      "id": Self.id(2), "title": "Stock Car", "tag": "stock-car",
      "comment": "Calendário de demonstração"
    ]
    categories = [f1, stock]
    races = [
      ["id": Self.id(10), "title": "Grande Prêmio de São Paulo", "shortTitle": "São Paulo",
       "category": f1, "earliestEventDate": Self.timestamp(now.addingTimeInterval(86400)),
       "events": [
         ["id": Self.id(100), "title": "Treino Livre", "date": Self.timestamp(now.addingTimeInterval(86400)), "isMainEvent": false],
         ["id": Self.id(101), "title": "Classificação", "date": Self.timestamp(now.addingTimeInterval(172800)), "isMainEvent": false],
         ["id": Self.id(102), "title": "Corrida", "date": Self.timestamp(now.addingTimeInterval(259200)), "isMainEvent": true]
       ]],
      ["id": Self.id(11), "title": "Stock Car em Interlagos", "shortTitle": "Interlagos",
       "category": stock, "earliestEventDate": Self.timestamp(now.addingTimeInterval(345600)),
       "events": [
         ["id": Self.id(110), "title": "Classificação", "date": Self.timestamp(now.addingTimeInterval(345600)), "isMainEvent": false, "isCancelled": true],
         ["id": Self.id(111), "title": "Corrida", "date": Self.timestamp(now.addingTimeInterval(432000)), "isMainEvent": true]
       ]],
      ["id": Self.id(12), "title": "Grande Prêmio com horário pendente", "shortTitle": "Horário pendente",
       "category": f1, "events": [
         ["id": Self.id(120), "title": "Corrida", "scheduledDay": String(Self.timestamp(now.addingTimeInterval(1209600)).prefix(10)), "isMainEvent": true]
       ]]
    ]
  }

  public func request<T: Decodable>(
    _: T.Type,
    endpoint: String,
    method: String,
    data: Data?,
    queryItems: [URLQueryItem],
    headers: [String: String]
  ) async throws -> T {
    try Task.checkCancellation()
    var body: [String: Any] = [:]
    if let data {
      guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw MockError.invalidBody("JSON")
      }
      body = object
    }
    let response = try response(endpoint: endpoint, method: method, body: body, queryItems: queryItems)
    let encoded = try JSONSerialization.data(withJSONObject: response)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(T.self, from: encoded)
  }

  // Headers are accepted for protocol compatibility; this service never opens a connection.
  public nonisolated func setPersistentHeaders(_ headers: [String: String]) {}

  private func response(endpoint: String, method: String, body: [String: Any], queryItems: [URLQueryItem]) throws -> Any {
    func query(_ name: String) -> String? {
      queryItems.first(where: { $0.name == name })?.value
    }
    switch (method, endpoint) {
    case ("GET", "admin-session"):
      // The separate mock app accepts any password without opening a connection.
      return ["authorized": true]
    case ("GET", "category"):
      return categories
    case ("POST", "category"):
      var category = body
      category["id"] = UUID().uuidString
      category["tag"] = try requiredString("categoryTag", in: body)
      categories.append(category)
      return category
    case ("PATCH", "category"):
      let id = try requiredString("id", in: body)
      guard let index = categories.firstIndex(where: { $0["id"] as? String == id }) else { throw MockError.missingRecord }
      categories[index] = body
      for index in races.indices where (races[index]["category"] as? [String: Any])?["id"] as? String == id {
        races[index]["category"] = body
      }
      return body
    case ("GET", "next-races"):
      return page(filteredRaces(tag: query("category")).filter(isUpcoming), queryItems: queryItems)
    case ("GET", "next-race"):
      guard let race = filteredRaces(tag: query("category")).first(where: isUpcoming) else { throw MockError.missingRecord }
      return race
    case ("GET", "race"):
      return filteredRaces(tag: query("tag"))
    case ("POST", "race"):
      let tag = try requiredString("categoryTag", in: body)
      guard let category = categories.first(where: { $0["tag"] as? String == tag }) else { throw MockError.missingRecord }
      var race = body
      race["id"] = UUID().uuidString
      race["category"] = category
      race["events"] = [[String: Any]]()
      race["earliestEventDate"] = normalizedDate(body["earliestEventDate"])
      races.append(race)
      return race
    case ("PATCH", "race"):
      let index = try raceIndex(id: requiredString("id", in: body))
      races[index]["title"] = body["title"]
      races[index]["shortTitle"] = body["shortTitle"]
      races[index]["earliestEventDate"] = normalizedDate(body["earliestEventDate"])
      return races[index]
    case ("GET", "events"):
      let index = try raceIndex(id: query("id") ?? "")
      return races[index]["events"] ?? [[String: Any]]()
    case ("POST", "events"):
      let index = try raceIndex(id: requiredString("raceID", in: body))
      guard let input = body["events"] as? [[String: Any]] else { throw MockError.invalidBody("events") }
      let events = input.map { event -> [String: Any] in
        var event = event
        event["id"] = event["id"] ?? UUID().uuidString
        event["date"] = normalizedDate(event["date"])
        return event
      }
      races[index]["events"] = events
      races[index]["earliestEventDate"] = events.compactMap { $0["date"] as? String }.min()
      return events
    case ("GET", "prune-race"):
      let tag = query("tag")
      races.removeAll { race in
        let category = race["category"] as? [String: Any]
        return (tag == nil || tag == category?["tag"] as? String) && !isUpcoming(race)
      }
      return filteredRaces(tag: tag)
    case ("GET", "import-settings"):
      return try importSettings(tag: query("category") ?? "")
    case ("PATCH", "import-settings"):
      let tag = try requiredString("categoryTag", in: body)
      var value = try importSettings(tag: tag)
      guard let enabled = body["enabled"] as? Bool,
        let interval = body["intervalDays"] as? Int, (1...365).contains(interval)
      else { throw MockError.invalidBody("enabled / intervalDays") }
      value["enabled"] = enabled
      value["intervalDays"] = interval
      value["nextImportAt"] = enabled ? Self.timestamp(Date().addingTimeInterval(Double(interval) * 86400)) : nil
      settings[tag] = value
      return value
    case ("GET", "imports"):
      let tag = query("category")
      return page(imports.filter { $0["categoryTag"] as? String == tag }, queryItems: queryItems)
    case ("POST", "import-refresh"):
      let tag = try requiredString("categoryTag", in: body)
      var value = try importSettings(tag: tag)
      let now = Date()
      let run: [String: Any] = [
        "id": UUID().uuidString, "categoryTag": tag, "provider": "mock", "trigger": "manual",
        "startedAt": Self.timestamp(now), "finishedAt": Self.timestamp(now), "status": "completed",
        "changes": [[String: Any]](), "issues": [[String: Any]]()
      ]
      imports.insert(run, at: 0)
      value["lastImportAt"] = Self.timestamp(now)
      value["nextImportAt"] = value["enabled"] as? Bool == true
        ? Self.timestamp(now.addingTimeInterval(Double(value["intervalDays"] as? Int ?? 7) * 86400)) : nil
      settings[tag] = value
      return run
    default:
      throw MockError.unsupportedRoute(method, endpoint)
    }
  }

  private func filteredRaces(tag: String?) -> [[String: Any]] {
    races.filter { race in
      guard let tag, !tag.isEmpty else { return true }
      return (race["category"] as? [String: Any])?["tag"] as? String == tag
    }
  }

  private func isUpcoming(_ race: [String: Any]) -> Bool {
    guard race["isCancelled"] as? Bool != true else { return false }
    let now = Self.timestamp(Date())
    return (race["events"] as? [[String: Any]] ?? []).contains { event in
      guard event["isCancelled"] as? Bool != true else { return false }
      if let date = event["date"] as? String { return date >= now }
      return (event["scheduledDay"] as? String ?? "") >= String(now.prefix(10))
    }
  }

  private func page(_ items: [[String: Any]], queryItems: [URLQueryItem]) -> [String: Any] {
    let page = max(1, Int(queryItems.first(where: { $0.name == "page" })?.value ?? "1") ?? 1)
    let per = min(100, max(1, Int(queryItems.first(where: { $0.name == "per" })?.value ?? "25") ?? 25))
    let (offset, overflow) = (page - 1).multipliedReportingOverflow(by: per)
    let start = overflow ? items.count : min(items.count, offset)
    return ["items": Array(items.dropFirst(start).prefix(per)), "metadata": ["page": page, "per": per, "total": items.count]]
  }

  private func importSettings(tag: String) throws -> [String: Any] {
    guard categories.contains(where: { $0["tag"] as? String == tag }) else { throw MockError.missingRecord }
    return settings[tag] ?? ["categoryTag": tag, "provider": "mock", "enabled": true, "intervalDays": 7]
  }

  private func raceIndex(id: String) throws -> Int {
    guard let index = races.firstIndex(where: { $0["id"] as? String == id }) else { throw MockError.missingRecord }
    return index
  }

  private func requiredString(_ key: String, in body: [String: Any]) throws -> String {
    guard let value = body[key] as? String, !value.isEmpty else { throw MockError.invalidBody(key) }
    return value
  }

  private func normalizedDate(_ value: Any?) -> String? {
    if let value = value as? String { return value }
    // Request.patch currently uses JSONEncoder's default reference-date representation.
    if let value = value as? Double { return Self.timestamp(Date(timeIntervalSinceReferenceDate: value)) }
    return nil
  }

  private static func timestamp(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }

  private static func id(_ value: Int) -> String {
    String(format: "00000000-0000-0000-0000-%012d", value)
  }
}

public enum MockError: LocalizedError {
  case missingRecord
  case invalidBody(String)
  case unsupportedRoute(String, String)

  public var errorDescription: String? {
    switch self {
    case .missingRecord: return "Registro não encontrado no calendário de demonstração."
    case .invalidBody(let field): return "Campo inválido na solicitação de demonstração: \(field)."
    case .unsupportedRoute(let method, let endpoint): return "Rota de demonstração não implementada: \(method) /\(endpoint)."
    }
  }
}
