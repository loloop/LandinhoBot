import Fluent
import Foundation

func upcomingRaces(on db: Database, now: Date = Date()) -> QueryBuilder<Race> {
  Race.query(on: db).filter(\.$isCancelled == false)
    .group(.or) { group in
      group.filter(\.$scheduleEndDate >= now)
      group.group(.and) { fallback in
        fallback.filter(\.$scheduleEndDate == nil).filter(\.$earliestEventDate >= now)
      }
    }
}
