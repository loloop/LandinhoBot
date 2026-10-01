import APIClient
import ComposableArchitecture
import XCTest
@testable import Settings

@MainActor
final class SettingsTests: XCTestCase {
  func testLockCancelsVerificationAndDiscardsLateSuccess() async {
    let clock = TestClock()
    let locks = LockIsolated(0)
    let store = TestStore(initialState: Settings.State()) { Settings() } withDependencies: {
      $0.adminAccess = .init(unlock: { _ in try await clock.sleep(for: .seconds(10)) }, lock: {
        locks.withValue { $0 += 1 }
      })
    }
    await store.send(.showPasswordPrompt) { $0.isPasswordPromptPresented = true }
    await store.send(.unlockAdmin("pending")) { $0.isUnlocking = true }
    await store.send(.lockAdmin) {
      $0.isPasswordPromptPresented = false
      $0.isUnlocking = false
    }
    await clock.advance(by: .seconds(10))
    await store.finish()
    await store.send(.unlockResponse(.success(true)))
    XCTAssertEqual(locks.value, 1)
  }

  func testAdministrationStaysHiddenUntilServerVerificationSucceeds() async {
    let store = TestStore(initialState: Settings.State()) { Settings() } withDependencies: {
      $0.adminAccess = .init(unlock: { _ in }, lock: {})
    }
    await store.send(.unlockAdmin("ignored"))
    await store.send(.showPasswordPrompt) { $0.isPasswordPromptPresented = true }
    await store.send(.unlockAdmin("verified")) { $0.isUnlocking = true }
    await store.receive(\.unlockResponse.success) {
      $0.isUnlocking = false
      $0.isPasswordPromptPresented = false
      $0.adminState = .init()
    }
    await store.send(.lockAdmin) { $0.adminState = nil }
  }

  func testWrongPasswordKeepsPromptOpenForAuthorizedRetry() async {
    let store = TestStore(initialState: Settings.State()) { Settings() } withDependencies: {
      $0.adminAccess = .init(unlock: { password in
        if password != "correct" { throw NSError(domain: "LandinhoAPI", code: 401) }
      }, lock: {})
    }
    await store.send(.showPasswordPrompt) { $0.isPasswordPromptPresented = true }
    await store.send(.unlockAdmin("wrong")) { $0.isUnlocking = true }
    await store.receive(\.unlockResponse.failure) {
      $0.isUnlocking = false
      $0.passwordError = "Senha incorreta. Tente novamente."
    }
    await store.send(.unlockAdmin("correct")) {
      $0.isUnlocking = true
      $0.passwordError = nil
    }
    await store.receive(\.unlockResponse.success) {
      $0.isUnlocking = false
      $0.isPasswordPromptPresented = false
      $0.adminState = .init()
    }
    await store.send(.adminAccessRevoked) { $0.adminState = nil }
  }

  func testUnconfiguredServerNeverOpensAdministration() async {
    let store = TestStore(initialState: Settings.State()) { Settings() } withDependencies: {
      $0.adminAccess = .init(unlock: { _ in throw NSError(domain: "LandinhoAPI", code: 503) }, lock: {})
    }
    await store.send(.showPasswordPrompt) { $0.isPasswordPromptPresented = true }
    await store.send(.unlockAdmin("anything")) { $0.isUnlocking = true }
    await store.receive(\.unlockResponse.failure) {
      $0.isUnlocking = false
      $0.passwordError = "A administração está indisponível. Contate o responsável pelo servidor."
    }
    await store.send(.passwordPromptDismissed) {
      $0.isPasswordPromptPresented = false
      $0.passwordError = nil
    }
    await store.send(.unlockResponse(.success(true)))
  }
}
