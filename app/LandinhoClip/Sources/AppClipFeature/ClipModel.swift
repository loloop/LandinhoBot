import Combine
import Foundation
import LandinhoFoundation

@MainActor
public final class ClipModel: ObservableObject {
  public enum Content: Equatable {
    case loading
    case categories([RaceCategory])
    case rounds([Race])
    case round(Race)
    case failure(String)
  }

  @Published public private(set) var navigation: ClipNavigation
  @Published public private(set) var content: Content = .loading
  private let client: ClipCalendarClient
  private let defaults: UserDefaults
  private var requestGeneration = 0
  private static let savedRouteKey = "clip.lastRoute"

  public init(client: ClipCalendarClient = .live(), defaults: UserDefaults = .standard) {
    self.client = client
    self.defaults = defaults
    self.navigation = ClipNavigation(restoredURL: defaults.string(forKey: Self.savedRouteKey).flatMap(URL.init(string:)))
  }

  public func receive(_ activity: NSUserActivity) {
    guard activity.activityType == NSUserActivityTypeBrowsingWeb else { return }
    navigation.receiveInvocation(activity.webpageURL)
    saveRoute()
  }

  public func navigate(to route: AppRoute) {
    navigation.navigate(to: route)
    saveRoute()
  }

  public func reload() async {
    requestGeneration += 1
    let generation = requestGeneration
    let snapshot = navigation
    content = .loading
    do {
      let result: Content
      switch snapshot.destination {
      case .categories:
        result = .categories(try await client.categories())
      case .category(let tag):
        result = .rounds(try await client.rounds(category: tag))
      case .round(let id):
        result = .round(try await client.round(id: id))
      case .home, .settings:
        result = .rounds(try await client.rounds(category: nil))
      }
      guard !Task.isCancelled, navigation == snapshot, generation == requestGeneration else { return }
      content = result
    } catch {
      guard !Task.isCancelled, navigation == snapshot, generation == requestGeneration else { return }
      let error = error as NSError
      content = .failure(error.domain == "LandinhoClipAPI" && error.code == 404
        ? "Esta etapa não está disponível. Confira as próximas etapas ou escolha uma categoria."
        : "Não foi possível carregar os horários. Confira sua conexão e tente novamente.")
    }
  }

  private func saveRoute() {
    defaults.set(navigation.fullAppRoute.url?.absoluteString, forKey: Self.savedRouteKey)
  }
}
