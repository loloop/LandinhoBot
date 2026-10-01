import Fluent
import Vapor

final class ImportRun: Model, Content {
  static let schema = "schedule_import"
  init() {}

  init(categoryTag: String, provider: String, trigger: String, now: Date) {
    self.id = UUID()
    self.categoryTag = categoryTag
    self.provider = provider
    self.trigger = trigger
    self.startedAt = now
    self.status = "running"
    self.changes = []
    self.issues = []
  }

  @ID(key: .id) var id: UUID?
  @Field(key: "category_tag") var categoryTag: String
  @Field(key: "provider") var provider: String
  @Field(key: "trigger") var trigger: String
  @Field(key: "started_at") var startedAt: Date
  @OptionalField(key: "finished_at") var finishedAt: Date?
  @Field(key: "status") var status: String
  @Field(key: "changes") var changes: [ImportChange]
  @Field(key: "issues") var issues: [ImportIssue]
}
