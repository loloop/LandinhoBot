import Fluent
import NIOCore
import Vapor

private struct ImporterKey: StorageKey { typealias Value = ScheduleImporter }

extension Application {
  var scheduleImporter: ScheduleImporter {
    get { storage[ImporterKey.self] ?? ScheduleImporter() }
    set { storage[ImporterKey.self] = newValue }
  }
}

final class ImportScheduling: LifecycleHandler, @unchecked Sendable {
  private var task: RepeatedTask?

  func didBoot(_ application: Application) throws {
    guard application.environment != .testing,
      Environment.get("SCHEDULE_IMPORTS_ENABLED") != "false" else { return }
    // This checks local due dates; provider fetches happen only at each category's interval.
    task = application.eventLoopGroup.next().scheduleRepeatedAsyncTask(initialDelay: .seconds(10), delay: .hours(1)) { _ in
      application.eventLoopGroup.next().makeFutureWithTask {
        let now = Date()
        let categories = try await Category.query(on: application.db).filter(\.$importsEnabled == true).all()
        for category in categories where category.nextImportAt.map({ $0 <= now }) ?? true {
          guard let tag = category.tag else { continue }
          do {
            _ = try await application.scheduleImporter.refresh(tag: tag, trigger: "scheduled", db: application.db, client: application.client, now: now)
          } catch let error as AbortError where error.status == .conflict {
            continue
          } catch {
            application.logger.error("Schedule import failed for \(tag): \(error)")
          }
        }
      }
    }
  }

  func shutdown(_ application: Application) {
    task?.cancel()
    task = nil
  }
}
