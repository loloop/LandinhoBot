import Foundation

/// Shared destinations for URL opening, App Clip invocation and app shortcuts.
public enum AppRoute: Equatable, Hashable, Sendable {
  case home
  case categories
  case category(tag: String)
  case settings
  case round(id: UUID)

  public static let scheme = "vroomvroom"
  /// Reserved for the future hosted Universal Link experience; sharing uses `url` today.
  public static let canonicalHost = "vroomvroom.racing"

  public init?(url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.user == nil, components.password == nil, components.port == nil,
      components.query == nil, components.fragment == nil
    else { return nil }

    let segments: [String]
    switch components.scheme?.lowercased() {
    case Self.scheme:
      guard let host = components.host, !host.isEmpty else { return nil }
      segments = [host] + Self.segments(in: components.percentEncodedPath)
    case "https":
      guard components.host?.lowercased() == Self.canonicalHost else { return nil }
      segments = Self.segments(in: components.percentEncodedPath)
    default:
      return nil
    }

    switch (segments.first, segments.count) {
    case ("home", 1): self = .home
    case ("categories", 1): self = .categories
    case ("settings", 1): self = .settings
    case ("categories", 2):
      guard let tag = segments[1].removingPercentEncoding, Self.isValidCategoryTag(tag) else { return nil }
      self = .category(tag: tag)
    case ("rounds", 2):
      guard let value = segments[1].removingPercentEncoding, value.utf8.count == 36,
        let id = UUID(uuidString: value) else { return nil }
      self = .round(id: id)
    default: return nil
    }
  }

  /// A registered custom-scheme URL that works when the app is installed.
  public var url: URL? { makeURL(isCanonical: false) }

  /// A future HTTPS URL. It requires a deployed website, AASA and associated domains.
  public var canonicalURL: URL? { makeURL(isCanonical: true) }

  private var segments: [String]? {
    switch self {
    case .home: return ["home"]
    case .categories: return ["categories"]
    case .settings: return ["settings"]
    case .category(let tag):
      return Self.isValidCategoryTag(tag) ? ["categories", tag] : nil
    case .round(let id): return ["rounds", id.uuidString.lowercased()]
    }
  }

  private func makeURL(isCanonical: Bool) -> URL? {
    guard let segments else { return nil }
    var components = URLComponents()
    components.scheme = isCanonical ? "https" : Self.scheme
    components.host = isCanonical ? Self.canonicalHost : segments[0]
    let path = isCanonical ? segments : Array(segments.dropFirst())
    components.path = path.isEmpty ? "" : "/" + path.joined(separator: "/")
    return components.url
  }

  private static func segments(in path: String) -> [String] {
    guard !path.isEmpty else { return [] }
    // Keep empty segments so duplicate or trailing slashes cannot change the destination.
    guard path.first == "/" else { return [""] }
    return path.dropFirst().components(separatedBy: "/")
  }

  private static func isValidCategoryTag(_ tag: String) -> Bool {
    !tag.isEmpty && tag.utf8.count <= 64 && tag.unicodeScalars.allSatisfy {
      CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_"
    }
  }
}

public extension Race {
  /// The Calendário F1 homepage is a generic web fallback, not a per-round page.
  var roundLinkFallbackURL: URL? {
    category.tag.lowercased() == "f1" ? URL(string: "https://calendariof1.com/") : nil
  }

  var roundLinkShareText: String {
    let link = AppRoute.round(id: id).url!.absoluteString
    var text = "\(category.title) — \(shortTitle)\nAbrir no VroomVroom: \(link)"
    if let fallback = roundLinkFallbackURL {
      text += "\nF1 na web (Calendário F1): \(fallback.absoluteString)"
    }
    return text
  }
}
