import Foundation
import LandinhoFoundation

/// A small, read-only adapter to the same public calendar API used by the full app.
/// No administration module, credential or persistent cookie store enters the Clip.
public struct ClipCalendarClient {
  public struct RoundPage: Decodable {
    public let items: [Race]
  }

  private let baseURL: URL
  private let fetch: (URLRequest) async throws -> (Data, URLResponse)

  public init(baseURL: URL = URL(string: "https://api.vroomvroom.racing")!,
    fetch: @escaping (URLRequest) async throws -> (Data, URLResponse) = { request in
      try await URLSession(configuration: .ephemeral).data(for: request)
    }) {
    self.baseURL = baseURL
    self.fetch = fetch
  }

  public static func live(environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
    if let value = environment["LANDINHO_API_URL"], let url = URL(string: value),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.user == nil, components.password == nil, components.query == nil, components.fragment == nil,
      components.scheme == "https" || (components.scheme == "http" && ["localhost", "127.0.0.1", "[::1]"].contains(components.host ?? "")) {
      return .init(baseURL: url)
    }
    return .init()
  }

  public func categories() async throws -> [RaceCategory] {
    try await get([RaceCategory].self, path: "category")
  }

  public func rounds(category: String?) async throws -> [Race] {
    var query = [URLQueryItem(name: "page", value: "1"), URLQueryItem(name: "per", value: "5")]
    if let category { query.append(.init(name: "category", value: category)) }
    return try await get(RoundPage.self, path: "next-races", query: query).items.filter { !$0.isCancelled }
  }

  public func round(id: UUID) async throws -> Race {
    let round = try await get(Race.self, path: "rounds/" + id.uuidString.lowercased())
    guard round.id == id else { throw URLError(.cannotDecodeContentData) }
    return round
  }

  private func get<T: Decodable>(_ type: T.Type, path: String, query: [URLQueryItem] = []) async throws -> T {
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { throw URLError(.badURL) }
    components.path = "/" + ([components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")), path]
      .filter { !$0.isEmpty }.joined(separator: "/"))
    components.queryItems = query.isEmpty ? nil : query
    guard let url = components.url else { throw URLError(.badURL) }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 20
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    let (data, response) = try await fetch(request)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw NSError(domain: "LandinhoClipAPI", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(type, from: data)
  }
}
