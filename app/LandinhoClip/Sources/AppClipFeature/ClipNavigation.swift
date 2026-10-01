import Foundation
import LandinhoFoundation

/// Only public schedule destinations are shown inside the Clip.
public struct ClipNavigation: Equatable {
  public private(set) var destination: AppRoute = .home
  public private(set) var fullAppRoute: AppRoute = .home
  public private(set) var notice: String?
  public private(set) var revision = 0

  public init(restoredURL: URL? = nil) {
    if let restoredURL, let route = AppRoute(url: restoredURL) { navigate(to: route) }
  }

  /// A launch without a URL retains the last destination, including after process termination.
  public mutating func receiveInvocation(_ url: URL?) {
    guard let url else { return }
    guard url.scheme?.lowercased() == "https", let route = AppRoute(url: url) else {
      destination = .home
      fullAppRoute = .home
      notice = "Não foi possível abrir este link. Confira as próximas etapas."
      revision += 1
      return
    }
    navigate(to: route)
  }

  public mutating func navigate(to route: AppRoute) {
    guard route.url != nil else { return }
    fullAppRoute = route
    notice = nil
    switch route {
    case .settings:
      destination = .home
      notice = "Os ajustes estão disponíveis no app completo."
    default:
      destination = route
    }
    revision += 1
  }
}
