import Foundation

/// Public distribution links are opt-in until the app and its Clip are released.
public struct AppSharing: Equatable, Sendable {
  public static let projectURL = URL(string: "https://github.com/loloop/LandinhoBot")!
  public let appClipURL: URL?
  public let appStoreURL: URL?

  public init(appClipURL: String? = nil, appStoreURL: String? = nil) {
    self.appClipURL = appClipURL.flatMap(URL.init(string:)).flatMap { url in
      url.scheme == "https" && AppRoute(url: url) != nil ? url : nil
    }
    self.appStoreURL = appStoreURL.flatMap(URL.init(string:)).flatMap { url in
      guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
        components.scheme == "https", components.host == "apps.apple.com",
        components.user == nil, components.password == nil, components.port == nil,
        components.query == nil, components.fragment == nil,
        let last = url.pathComponents.last, last.hasPrefix("id"),
        !last.dropFirst(2).isEmpty, last.dropFirst(2).allSatisfy({ "0"..."9" ~= $0 })
      else { return nil }
      return url
    }
  }

  public init(bundle: Bundle) {
    self.init(
      appClipURL: bundle.object(forInfoDictionaryKey: "VroomVroomAppClipURL") as? String,
      appStoreURL: bundle.object(forInfoDictionaryKey: "VroomVroomAppStoreURL") as? String)
  }

  public var shareText: String {
    if let appClipURL {
      return "VroomVroom — acompanhe os horários do automobilismo.\n\(appClipURL.absoluteString)"
    }
    if let appStoreURL {
      return "VroomVroom — acompanhe os horários do automobilismo.\n\(appStoreURL.absoluteString)"
    }
    return "VroomVroom — acompanhe os horários do automobilismo.\nAbrir o app instalado: \(AppRoute.home.url!.absoluteString)\nProjeto VroomVroom: \(Self.projectURL.absoluteString)"
  }

  public var explanation: String {
    if appClipURL != nil { return "Compartilhe uma prévia do calendário com o App Clip." }
    if appStoreURL != nil { return "Compartilhe o VroomVroom na App Store." }
    return "Compartilhe o projeto VroomVroom e um link para abrir o app instalado."
  }
}
