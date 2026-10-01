/// Stable Home Screen action identifiers declared in the app's Info.plist.
public enum HomeScreenQuickAction: String, CaseIterable, Sendable {
  case upcomingSessions = "me.mauriciocardozo.racing.vroomvroom.quick-action.upcoming-sessions"
  case categories = "me.mauriciocardozo.racing.vroomvroom.quick-action.categories"
  case settings = "me.mauriciocardozo.racing.vroomvroom.quick-action.settings"

  public var route: AppRoute {
    switch self {
    case .upcomingSessions: return .home
    case .categories: return .categories
    case .settings: return .settings
    }
  }
}
