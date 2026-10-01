import LandinhoFoundation

/// The next session is prominent; the remaining sessions read down each column.
struct ExtraLargeWidgetSchedule {
  let nextSession: RaceEvent?
  let columns: [[RaceEvent]]
  let hiddenSessionCount: Int

  init(content: WidgetScheduleContent, rowsPerColumn: Int) {
    let sessions = content.events
    nextSession = sessions.first
    let remaining = sessions.dropFirst()
    let visible = Array(remaining.prefix(max(0, rowsPerColumn) * 2))
    let split = (visible.count + 1) / 2
    columns = visible.isEmpty ? [] : [Array(visible.prefix(split)), Array(visible.dropFirst(split))]
      .filter { !$0.isEmpty }
    hiddenSessionCount = remaining.count - visible.count
  }
}
