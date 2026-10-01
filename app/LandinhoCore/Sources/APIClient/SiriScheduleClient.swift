import Foundation
import LandinhoFoundation

/// Siri uses the same public API configuration as the app, without admin credentials.
public enum SiriScheduleClient {
  public static func upcomingRounds(categoryTag: String?) async throws -> [Race] {
    try await UpcomingScheduleLoading.rounds { page in
      try await APIClientService.live.request(
        UpcomingSchedulePage.self,
        endpoint: "next-races",
        method: "GET",
        data: nil,
        queryItems: [
          URLQueryItem(name: "category", value: categoryTag ?? ""),
          URLQueryItem(name: "page", value: String(page)),
          URLQueryItem(name: "per", value: "100")
        ],
        headers: [:])
    }
  }

  public static func categories() async throws -> [RaceCategory] {
    try await APIClientService.live.request(
      [RaceCategory].self, endpoint: "category", method: "GET", data: nil, queryItems: [], headers: [:])
  }
}
