import AppIntents
import ComposableArchitecture
import Foundation
import Settings
import SwiftUI

// Evidence source only. Temporarily replace VroomVroomApp.swift with this file,
// restore the shipping entry, then run the final app/Widget/App Clip build.
// Calls the committed AppIntent.perform(); this is not a spoken Siri invocation.
@main
struct VroomVroomApp: App {
  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate
  private let mode = ProcessInfo.processInfo.environment["LANDINHO_SIRI_EVIDENCE"] ?? "race"

  init() { RacingScheduleShortcuts.updateAppShortcutParameters() }

  var body: some Scene {
    WindowGroup {
      if mode == "settings" {
        NavigationStack {
          SettingsView(store: Store(initialState: Settings.State()) { Settings() })
        }
      } else {
        SiriQueryEvidenceView(mode: mode)
      }
    }
  }
}

private struct SiriQueryEvidenceView: View {
  let mode: String
  @State private var message: String?
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("App Intent · execução nativa")
            .font(.caption)
            .foregroundStyle(.secondary)
          if let message {
            // The exact production snippet, using the value returned by perform().
            RacingScheduleSnippet(message: message)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
          } else if let errorMessage {
            Label("Calendário indisponível", systemImage: "wifi.exclamationmark")
              .font(.headline)
            Text(errorMessage)
              .fixedSize(horizontal: false, vertical: true)
          } else {
            ProgressView("Consultando calendário…")
          }
        }
        .padding(24)
      }
      .navigationTitle(isSession ? "Próxima sessão" : "Próxima corrida")
      .task { await runIntent() }
    }
  }

  @MainActor
  private func runIntent() async {
    let intent = AskNextRacingSessionIntent(sessionKind: isSession ? .session : .race)
    do {
      if ["category", "mock", "mock-session"].contains(mode) {
        let matches = try await RacingCategoryQuery().entities(matching: "F1")
        guard let category = matches.first else { throw SiriEvidenceError.missingCategory }
        intent.category = category
      }
      let returnedValue: String?
      if isSession {
        let sessionIntent = AskNextSessionTimeIntent()
        sessionIntent.category = intent.category
        returnedValue = try await sessionIntent.perform().value
      } else {
        returnedValue = try await intent.perform().value
      }
      guard let value = returnedValue else { throw SiriEvidenceError.missingValue }
      message = value
      saveResult(text: value, error: nil, categoryTag: intent.category?.tag)
    } catch {
      let value = error.localizedDescription
      errorMessage = value
      saveResult(text: nil, error: value, categoryTag: intent.category?.tag)
    }
  }

  private var isSession: Bool { mode == "session" || mode == "mock-session" }

  private func saveResult(text: String?, error: String?, categoryTag: String?) {
    let result = SiriEvidenceResult(
      mode: mode, text: text, error: error, categoryTag: categoryTag,
      bundleLocalizations: Bundle.main.localizations,
      developmentLocalization: Bundle.main.developmentLocalization,
      networkingMode: networkingMode,
      apiURLOverride: ProcessInfo.processInfo.environment["LANDINHO_API_URL"])
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    do {
      let data = try JSONEncoder().encode(result)
      try data.write(to: directory.appendingPathComponent("SiriEvidence.json"), options: .atomic)
      print("SIRI_EVIDENCE \(String(decoding: data, as: UTF8.self))")
    } catch { print("SIRI_EVIDENCE_WRITE_FAILED \(error.localizedDescription)") }
  }

  private var networkingMode: String {
    #if MOCK_NETWORKING
    "mock"
    #else
    "live"
    #endif
  }
}

private struct SiriEvidenceResult: Encodable {
  let mode: String
  let text: String?
  let error: String?
  let categoryTag: String?
  let bundleLocalizations: [String]
  let developmentLocalization: String?
  let networkingMode: String
  let apiURLOverride: String?
}

private enum SiriEvidenceError: LocalizedError {
  case missingCategory
  case missingValue
  var errorDescription: String? {
    switch self {
    case .missingCategory: "The fixture category query returned no F1 match."
    case .missingValue: "AppIntent.perform() did not return its required answer value."
    }
  }
}
