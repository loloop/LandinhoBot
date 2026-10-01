import Foundation
import Vapor

struct FormulaOneProvider: ScheduleProvider {
  let id = "official-f1"
  let categoryTag = "f1"
  private let origin = "https://www.formula1.com"

  func fetch(client: Client, now: Date) async throws -> ScheduleSnapshot {
    let year = Calendar(identifier: .gregorian).component(.year, from: now)
    let paths = try await Self.calendarPaths(startingWith: year) { season in
      try await download("\(origin)/en/racing/\(season)", client: client, allowNotFound: true)
    }

    var meetings: [SourceMeeting] = []
    var issues: [ImportIssue] = []
    let urls = Set(paths.map { origin + $0 })
    for url in urls.sorted() {
      do {
        guard let html = try await download(url, client: client) else { throw Abort(.badGateway) }
        let meeting = try Self.parseMeeting(html: html, sourceURL: url)
        meetings.append(meeting)
      } catch {
        issues.append(.init(title: "F1 meeting could not be imported", message: String(describing: error), sourceURL: url))
      }
    }
    return .init(meetings: meetings, discoveredURLs: urls, issues: issues)
  }

  private func download(_ url: String, client: Client, allowNotFound: Bool = false) async throws -> String? {
    let response = try await client.get(URI(string: url)) { request in
      request.headers.replaceOrAdd(name: .userAgent, value: "LandinhoBot/1.0 (schedule importer)")
    }
    if allowNotFound && response.status == .notFound { return nil }
    guard response.status == .ok, let body = response.body,
      let html = body.getString(at: body.readerIndex, length: body.readableBytes), html.utf8.count < 5_000_000
    else { throw Abort(.badGateway, reason: "Unable to read official schedule at \(url)") }
    return html
  }

  static func calendarPaths(startingWith year: Int, loadSeason: (Int) async throws -> String?) async throws -> Set<String> {
    var pending: Set<Int> = [year]
    var visited = Set<Int>()
    var paths = Set<String>()
    while let season = pending.min() {
      pending.remove(season)
      guard visited.insert(season).inserted else { continue }
      // Bound malformed discovery rather than silently truncating a published calendar.
      guard visited.count <= 20 else { throw Abort(.badGateway, reason: "Unexpected F1 season discovery loop") }
      guard let html = try await loadSeason(season) else {
        guard season != year else { throw Abort(.badGateway, reason: "Current F1 calendar is unavailable") }
        continue
      }
      let seasonPaths = meetingPaths(in: html).filter { $0.hasPrefix("/en/racing/\(season)/") }
      guard !seasonPaths.isEmpty else {
        throw Abort(.badGateway, reason: "The official F1 calendar contains no recognisable meetings for \(season)")
      }
      paths.formUnion(seasonPaths)
      pending.formUnion(seasonYears(in: html).filter { $0 >= year && !visited.contains($0) })
      // F1 can publish the next season without linking it from the current calendar.
      if !visited.contains(season + 1) { pending.insert(season + 1) }
    }
    return paths
  }

  static func seasonYears(in html: String) -> Set<Int> {
    Set(matches(#"/en/racing/(\d{4})(?:["/\?#])"#, in: html).compactMap { Int($0[1]) })
  }

  static func meetingPaths(in html: String) -> [String] {
    matches(#"href="(/en/racing/\d{4}/[a-z0-9-]+)""#, in: html).map { $0[1] }
  }

  static func parseMeeting(html: String, sourceURL: String) throws -> SourceMeeting {
    // React Flight envelopes contain JSON strings. Decode them; never execute upstream JS.
    let chunks = matches(#"self\.__next_f\.push\((\[.*?\])\)</script>"#, in: html)
      .compactMap { match -> String? in
        guard let data = match[1].data(using: .utf8),
          let envelope = try? JSONSerialization.jsonObject(with: data) as? [Any],
          envelope.count > 1 else { return nil }
        return envelope[1] as? String
      }.joined()
    guard let marker = chunks.range(of: "\"pageData\":"),
      let object = jsonObjectPrefix(String(chunks[marker.upperBound...])),
      let data = object.data(using: .utf8),
      let page = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let race = page["race"] as? [String: Any],
      let meetingID = identifier(race["meetingKey"]),
      let title = race["meetingName"] as? String,
      let startValue = race["meetingStartDate"] as? String,
      let endValue = race["meetingEndDate"] as? String,
      let start = ScheduleDates.parse(startValue), let end = ScheduleDates.parse(endValue), end >= start
    else { throw Abort(.unprocessableEntity, reason: "Unrecognisable F1 meeting payload") }

    let rawSessions: [[String: Any]]
    if let value = race["meetingSessions"] {
      guard let sessions = value as? [[String: Any]] else { throw Abort(.unprocessableEntity, reason: "Malformed F1 sessions") }
      rawSessions = sessions
    } else { rawSessions = [] }

    let overrides = page["eventStatusOverride"] as? [String: Any] ?? [:]
    let eventOverride = overrides["event"] as? [String: Any] ?? [:]
    let cancelled = isCancelled(eventOverride["status"] as? String ?? race["meetingStatus"] as? String)
    let sessionOverrides = overrides["sessions"] as? [[String: Any]] ?? []
    var ids = Set<String>()
    let sessions = try rawSessions.map { session -> SourceSession in
      guard let key = identifier(session["meetingSessionKey"]), ids.insert(key).inserted,
        let name = session["description"] as? String, !name.isEmpty
      else { throw Abort(.unprocessableEntity, reason: "Missing or duplicate F1 session identity") }
      let code = session["session"] as? String ?? ""
      let override = sessionOverrides.first { $0["session"] as? String == code }
      let status = (override?["status"] as? String ?? session["sessionStatus"] as? String ?? "").lowercased()
      let local = session["startTime"] as? String
      let pending = ["tbc", "tbd", "pending", "postponed"].contains(status) || local == nil
      let date: Date?
      if pending {
        date = nil
      } else {
        guard let local else { throw Abort(.unprocessableEntity) }
        // The payload's explicit UTC offset is authoritative; machine timezone is irrelevant.
        let hasOffset = local.hasSuffix("Z") || local.range(of: #"[+-]\d{2}:\d{2}$"#, options: .regularExpression) != nil
        guard let value = hasOffset ? local : (session["gmtOffset"] as? String).map({ local + $0 }),
          let parsed = ScheduleDates.parse(value)
        else { throw Abort(.unprocessableEntity, reason: "Missing or malformed F1 session timezone") }
        date = parsed
      }
      return SourceSession(id: key, title: name, date: date,
        scheduledDay: local.map { String($0.prefix(10)) },
        isMainEvent: ["r", "s"].contains(code) || (session["sessionType"] as? String == "Race"),
        isCancelled: cancelled || isCancelled(status))
    }
    return SourceMeeting(id: meetingID, title: title,
      shortTitle: String((race["circuitShortName"] as? String ?? title).prefix(23)),
      sourceURL: sourceURL, startDate: start, endDate: end, isCancelled: cancelled, sessions: sessions)
  }

  private static func identifier(_ value: Any?) -> String? {
    if let string = value as? String, !string.isEmpty { return string }
    if let number = value as? NSNumber { return number.stringValue }
    return nil
  }

  private static func isCancelled(_ value: String?) -> Bool {
    ["cancelled", "canceled"].contains(value?.lowercased() ?? "")
  }

  private static func matches(_ pattern: String, in text: String) -> [[String]] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else { return [] }
    let ns = text as NSString
    return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).map { match in
      (0..<match.numberOfRanges).map { ns.substring(with: match.range(at: $0)) }
    }
  }

  private static func jsonObjectPrefix(_ input: String) -> String? {
    var depth = 0
    var quoted = false
    var escaped = false
    guard input.first == "{" else { return nil }
    for index in input.indices {
      let char = input[index]
      if quoted {
        if escaped { escaped = false }
        else if char == "\\" { escaped = true }
        else if char == "\"" { quoted = false }
      } else {
        if char == "\"" { quoted = true }
        else if char == "{" { depth += 1 }
        else if char == "}" {
          depth -= 1
          if depth == 0 { return String(input[...index]) }
        }
      }
    }
    return nil
  }
}
