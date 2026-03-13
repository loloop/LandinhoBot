//
//  AlertDispatcher.swift
//
//
//  Created for LandinhoBot subscription feature
//

import Foundation
import TelegramBotSDK

actor AlertDispatcher {

  private var sentAlerts: Set<String> = []
  private let bot: TelegramBot

  private static let formatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd/MM 'às' HH:mm"
    return f
  }()

  init(bot: TelegramBot) {
    self.bot = bot
  }

  // nonisolated so it can be called from sync context (e.g. DefaultVroomBot.init)
  nonisolated func start() {
    Task {
      while true {
        await checkAndSendAlerts(thresholdSeconds: 3600, label: "1h")
        await checkAndSendAlerts(thresholdSeconds: 86400, label: "24h")
        try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
      }
    }
  }

  private func checkAndSendAlerts(thresholdSeconds: Int, label: String) async {
    let api = APIClient<[AlertItem]>(endpoint: "upcoming-alerts")
    let alerts: [AlertItem]

    do {
      alerts = try await api.fetch(arguments: ["threshold": "\(thresholdSeconds)"])
    } catch {
      return
    }

    for alert in alerts {
      let alertKey = "\(alert.eventDate.timeIntervalSince1970):\(alert.categoryTag):\(label)"
      guard !sentAlerts.contains(alertKey) else { continue }

      sentAlerts.insert(alertKey)

      let message = formatAlert(alert, label: label)
      for chatIDString in alert.chatIDs {
        guard let chatID = Int64(chatIDString) else { continue }
        try? await bot.sendMessageAsync(chatId: .chat(chatID), text: message)
      }
    }
  }

  private func formatAlert(_ alert: AlertItem, label: String) -> String {
    let timeLabel = label == "1h" ? "em 1 hora" : "amanha"
    let dateString = Self.formatter.string(from: alert.eventDate)
    return """
    \u{1F3C1} [\(alert.categoryTitle)] \(alert.raceTitle)
    \(alert.eventTitle) – \(timeLabel)!
    \u{1F4C5} \(dateString)
    """
  }
}
