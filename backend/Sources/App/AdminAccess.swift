import Vapor

/// The shared credential is supplied by deployment, never by the app binary.
struct AdminPasswordMiddleware: AsyncMiddleware {
  private let passwordDigest: [UInt8]?

  init(password: String?) {
    if let password, !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      passwordDigest = Array(SHA256.hash(data: Data(password.utf8)))
    } else {
      passwordDigest = nil
    }
  }

  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    guard let expected = passwordDigest else {
      throw Abort(.serviceUnavailable, reason: "Administrator access is not configured")
    }
    guard let credentials = request.headers.basicAuthorization, credentials.username == "admin" else {
      throw unauthorized()
    }
    // Compare fixed-length digests without stopping at the first different byte.
    let supplied = Array(SHA256.hash(data: Data(credentials.password.utf8)))
    guard expected.secureCompare(to: supplied) else { throw unauthorized() }
    let response = try await next.respond(to: request)
    response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
    return response
  }

  private func unauthorized() -> Abort {
    Abort(.unauthorized, headers: ["WWW-Authenticate": "Basic realm=\"Landinho administration\", charset=\"UTF-8\""],
      reason: "Administrator password required")
  }
}

/// Keep this partition explicit: schedule reads and Telegram subscriptions remain public.
func registerRoutes(in app: Application, adminPassword: String? = Environment.get("LANDINHO_ADMIN_PASSWORD")) {
  let publicHandlers: [any AsyncRequestHandler] = [
    CategoryListHandler(), NextRaceHandler(), NextRacesHandler(), RaceListHandler(), EventListHandler(),
    SubscribeHandler(), UnsubscribeHandler(), ChatSubscriptionsHandler(), UpcomingAlertsHandler()
  ]
  publicHandlers.register(in: app)

  let admin = app.grouped(AdminPasswordMiddleware(password: adminPassword))
  let adminHandlers: [any AsyncRequestHandler] = [
    UploadCategoryHandler(), UpdateCategoryHandler(), UploadRaceHandler(), UpdateRaceHandler(),
    UpdateEventsHandler(), PruneRaceHandler(), ImportSettingsHandler(), UpdateImportSettingsHandler(),
    RefreshImportHandler(), ImportHistoryHandler(), ResolveImportMatchHandler()
  ]
  adminHandlers.register(in: admin)
  // Verifies the password before the app opens any administration screen.
  admin.get("admin-session") { _ -> AdminSessionResponse in .init(authorized: true) }
}

private struct AdminSessionResponse: Content {
  let authorized: Bool
}
