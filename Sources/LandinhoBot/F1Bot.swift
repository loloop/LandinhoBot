//
//  TelegramBot.swift
//  
//
//  Created by Mauricio Cardozo on 15/03/23.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import TelegramBotSDK
import OpenCombine
import OpenCombineFoundation

final class F1Bot {

  static let formatter = {
    let fm = DateFormatter()
    fm.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return fm
  }()
  let nextRaceCommand = BotCommand(
    command: "/nextRace",
    description: "Sends next race times")
  let telegram: TelegramBot
  let publisher: URLSession.OCombine.DataTaskPublisher
  var cancellables = Set<AnyCancellable>()
  var events: [F1CalendarEvent] = []


  init() {
    telegram = TelegramBot(token: Environment.telegramToken)
    publisher = URLSession.shared.ocombine.dataTaskPublisher(for: calendarURL)
    setUpBotCommands()
    setUpPublisher()
  }

  func setUpBotCommands() {
    telegram.setMyCommandsSync(commands: [nextRaceCommand])
  }

  func setUpPublisher() {
    publisher
      .tryMap { data, response in
        guard
          let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200
        else {
          throw URLError(.badServerResponse)
        }
        return data
      }
      .decode(type: [F1CalendarEvent].self, decoder: JSONDecoder())
      .sink { _ in }
      receiveValue: { [weak self] events in
        self?.events = Self.filterEvents(events)
      }
      .store(in: &cancellables)
  }

  func update() {
    while let update = telegram.nextUpdateSync() {
      dump(update)
      guard
        let message = update.message,
        message.text?.lowercased() == nextRaceCommand.command.lowercased()
      else {
        continue
      }

      guard let nextEvent = Self.filterEvents(events).first else {
        telegram.reply(update, text: "Couldn't find next race")
        return
      }

      let formattedEvent = formatEvent(nextEvent)
      telegram.reply(update, text: formattedEvent)
    }
  }

  func formatEvent(_ event: F1CalendarEvent) -> String {
    return
"""
\(event.raceName.capitalized) at \(event.circuitName.capitalized)

🏎️🏎️🏎️🏎️🏎️🏎️🏎️

\(formatTimes(for: event))

🏎️🏎️🏎️🏎️🏎️🏎️🏎️

Event data by CalendarioF1.com
"""
  }

  func formatTimes(for event: F1CalendarEvent) -> String {
    let times: [String] = event.times
      .compactMap(\.brlStartTime)
      .reversed()

    if event.isSprint_🔥🔥__HACK__🔥🔥 {
      return formatSprintWeekend(times)
    }
    return formatRegularWeekend(times)
  }

  func formatRegularWeekend(_ times: [String]) -> String {
"""
Practice 1 \(times[0])
Practice 2 \(times[1])
Practice 3 \(times[2])
Quali \(times[3])
Race \(times[4])
"""
  }

  func formatSprintWeekend(_ times: [String]) -> String {
"""
Practice 1 \(times[0])
Qualifying \(times[1])
Practice 2 \(times[2])
Sprint \(times[3])
Race \(times[4])
"""
  }

  static func filterEvents(_ events: [F1CalendarEvent]) -> [F1CalendarEvent] {
    events.filter {
      guard
        $0.eventType == nil,
        let dateString = $0.times.first?.startTime,
        let raceDate = Self.formatter.date(from: dateString)
      else {
        return false
      }

      let dateComparison = Calendar
        .autoupdatingCurrent
        .compare(
          Date(),
          to: raceDate,
          toGranularity: .day)

      return dateComparison == .orderedAscending
    }
  }
}
