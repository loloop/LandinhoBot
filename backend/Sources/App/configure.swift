import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "race_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "race_password",
        database: Environment.get("DATABASE_NAME") ?? "race_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

  app.migrations.add(v0_1Migration())
  app.migrations.add(v0_2Migration())
  app.migrations.add(v0_3Migration())
  app.migrations.add(v0_4Migration())

  [
    // category
    UploadCategoryHandler(),
    CategoryListHandler(),
    UpdateCategoryHandler(),

    // next-race
    NextRaceHandler(),

    // next-races
    NextRacesHandler(),

    // race
    RaceListHandler(),
    UpdateRaceHandler(),
    UploadRaceHandler(),

    // prune-race
    PruneRaceHandler(),

    // events
    EventListHandler(),
    UpdateEventsHandler(),

    // subscriptions
    SubscribeHandler(),
    UnsubscribeHandler(),
    ChatSubscriptionsHandler(),

    // alerts
    UpcomingAlertsHandler(),

    ImportSettingsHandler(),
    UpdateImportSettingsHandler(),
    RefreshImportHandler(),
    ImportHistoryHandler(),
    ResolveImportMatchHandler()
  ].register(in: app)

   try await app.autoMigrate()

  if let category = try await Category.query(on: app.db).filter(\.$tag == "f1").first() {
    if category.importProvider == nil {
      category.importProvider = "official-f1"
      category.importsEnabled = true
      category.nextImportAt = Date()
      try await category.save(on: app.db)
    }
  } else {
    let category = Category(title: "Formula 1", tag: "f1", comment: "Calendário oficial: https://www.formula1.com/en/racing")
    category.importProvider = "official-f1"
    category.importsEnabled = true
    category.nextImportAt = Date()
    try await category.create(on: app.db)
  }
  app.lifecycle.use(ImportScheduling())
}
