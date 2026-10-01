import ComposableArchitecture
import Foundation
import LandinhoFoundation
import Router
import SwiftUI
import UIKit

// Evidence source only. Temporarily replace the app entry; restore it before shipping.
// The trigger calls production scene methods, not a Home Screen long press.
@main
@MainActor
struct VroomVroomApp: App {
  let store: StoreOf<Root>
  let mode = ProcessInfo.processInfo.environment["LANDINHO_QUICK_ACTION_EVIDENCE"] ?? "before"
  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate

  init() {
    let mode = ProcessInfo.processInfo.environment["LANDINHO_QUICK_ACTION_EVIDENCE"] ?? "before"
    UserDefaults.standard.set(mode != "beta", forKey: QuickActionValidation.betaSheetKey)
    store = Store(initialState: Root.State()) { Root() }
  }

  var body: some Scene {
    WindowGroup {
      QuickActionEvidenceView(store: store, mode: mode)
    }
  }
}

@MainActor
private struct QuickActionEvidenceView: View {
  let store: StoreOf<Root>
  let mode: String
  @EnvironmentObject var sceneDelegate: VroomSceneDelegate
  @State private var isReady = false
  @State private var didPrepare = false
  @State private var testReport = "Running native quick-action validation…"

  var body: some View {
    if mode == "tests" {
      Text(testReport)
        .task {
          guard !didPrepare else { return }
          didPrepare = true
          guard let scene = sceneDelegate.windowScene else {
            testReport = "No native window scene"
            return
          }
          testReport = QuickActionValidation.run(in: scene)
        }
    } else if isReady {
      RootView(store: store)
        .task {
          switch mode {
          case "warm-settings", "warm-home", "unknown":
            try? await Task.sleep(for: .seconds(8))
            guard let scene = sceneDelegate.windowScene else { return }
            let type = mode == "unknown" ? "unrecognized-action"
              : (mode == "warm-home" ? HomeScreenQuickAction.upcomingSessions.rawValue
                 : HomeScreenQuickAction.settings.rawValue)
            sceneDelegate.windowScene(scene, performActionFor: shortcut(type)) { handled in
              print("Warm shortcut \(type): handled=\(handled)")
            }
          case "beta":
            try? await Task.sleep(for: .seconds(15))
            store.send(.setBetaSheet(false))
          default:
            break
          }
        }
    } else {
      Color.clear
        .task {
          guard !didPrepare else { return }
          didPrepare = true
          switch mode {
          case "cold-categories":
            sceneDelegate.handleQuickAction(shortcut(HomeScreenQuickAction.categories.rawValue))
          case "cold-settings", "beta":
            sceneDelegate.handleQuickAction(shortcut(HomeScreenQuickAction.settings.rawValue))
          case "warm-home":
            // Start in an existing detail destination so the Home action must clear navigation.
            store.send(.openURL(AppRoute.category(tag: "f1").url!))
          default:
            break
          }
          isReady = true
        }
    }
  }
}

@MainActor
private func shortcut(_ type: String) -> UIApplicationShortcutItem {
  UIApplicationShortcutItem(type: type, localizedTitle: "Evidence trigger")
}

@MainActor
private enum QuickActionValidation {
  static var betaSheetKey: String {
    let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "x"
    return "me.mauriciocardozo.racing.vroomvroom.betasheet-v\(version)"
  }

  private final class Trace {
    var actions: [Root.Action] = []
    var invocationCount: Int {
      actions.filter { if case .openURL = $0 { return true }; return false }.count
    }
    var navigationCount: Int {
      actions.filter { if case .router(.openRoute(_)) = $0 { return true }; return false }.count
    }
  }

  private struct Failure: Error { let message: String }

  private static func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw Failure(message: message) }
  }

  private static func makeStore(_ trace: Trace) -> StoreOf<Root> {
    Store(initialState: Root.State()) {
      Reduce<Root.State, Root.Action> { _, action in
        trace.actions.append(action)
        return .none
      }
      Root()
    }
  }

  static func run(in scene: UIWindowScene) -> String {
    let previousBetaPreference = UserDefaults.standard.object(forKey: betaSheetKey)
    defer {
      if let previousBetaPreference {
        UserDefaults.standard.set(previousBetaPreference, forKey: betaSheetKey)
      } else {
        UserDefaults.standard.removeObject(forKey: betaSheetKey)
      }
    }

    let cases: [(String, () throws -> Void)] = [
      ("prebinding_delivered_once", prebindingDeliveredOnce),
      ("latest_action_before_bind", latestActionBeforeBind),
      ("warm_actions_and_completion", { try warmActionsAndCompletion(in: scene) }),
      ("unknown_warm_action", { try unknownWarmAction(in: scene) }),
      ("beta_deferral", { try betaDeferral(in: scene) }),
      ("delegate_store_isolation", delegateStoreIsolation),
    ]
    var results: [[String: Any]] = []
    for (name, run) in cases {
      UserDefaults.standard.set(true, forKey: betaSheetKey)
      do {
        try run()
        results.append(["name": name, "passed": true])
      } catch {
        let message = (error as? Failure)?.message ?? String(describing: error)
        results.append(["name": name, "passed": false, "failure": message])
      }
    }
    let failures = results.filter { $0["passed"] as? Bool == false }.count
    let report = "Native quick actions: \(cases.count) tests, \(failures) failures"
    print(report)
    do {
      let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("quick-actions-tests.json")
      let data = try JSONSerialization.data(withJSONObject: [
        "tests": results, "count": cases.count, "failures": failures,
        "trigger": "production scene methods and Root store; no OS Home Screen interaction",
      ], options: [.prettyPrinted, .sortedKeys])
      try data.write(to: output, options: .atomic)
    } catch {
      print("Could not write native test evidence: \(error)")
    }
    return report
  }

  private static func prebindingDeliveredOnce() throws {
    let delegate = VroomSceneDelegate()
    let trace = Trace()
    let store = makeStore(trace)
    try check(delegate.handleQuickAction(shortcut(HomeScreenQuickAction.settings.rawValue)),
      "Cold action was not accepted")
    try check(trace.invocationCount == 0, "Action was sent before the scene had a store")
    delegate.bindRootStore(store)
    try check(store.withState { !$0.hasAppeared && $0.pendingRoute == .settings },
      "Root did not queue the launch action before appearing")
    store.send(.onAppear)
    try check(store.withState { $0.pendingRoute == nil && $0.router.selectedTab == .settings },
      "Startup did not deliver the pending Settings destination")
    store.send(.router(.selectTab(.home)))
    delegate.bindRootStore(store)
    try check(trace.invocationCount == 1 && trace.navigationCount == 1,
      "Rebinding replayed the launch action")
    try check(store.withState { $0.router.selectedTab == .home },
      "Rebinding unexpectedly navigated away from the user's selected tab")
  }

  private static func latestActionBeforeBind() throws {
    let delegate = VroomSceneDelegate()
    let trace = Trace()
    let store = makeStore(trace)
    delegate.handleQuickAction(shortcut(HomeScreenQuickAction.settings.rawValue))
    delegate.handleQuickAction(shortcut(HomeScreenQuickAction.categories.rawValue))
    try check(!delegate.handleQuickAction(shortcut("unrecognized-action")),
      "Unknown action was accepted")
    delegate.bindRootStore(store)
    try check(store.withState { $0.pendingRoute == .categories },
      "Latest valid invocation did not win or was erased by the unknown action")
    store.send(.onAppear)
    try check(trace.invocationCount == 1 && store.withState { $0.router.selectedTab == .categories },
      "Startup delivered an obsolete shortcut")
  }

  private static func warmActionsAndCompletion(in scene: UIWindowScene) throws {
    let delegate = VroomSceneDelegate()
    let trace = Trace()
    let store = makeStore(trace)
    delegate.bindRootStore(store)
    store.send(.onAppear)
    let destinations: [(HomeScreenQuickAction, Router.Tab)] = [
      (.settings, .settings), (.categories, .categories), (.upcomingSessions, .home),
    ]
    for (action, destination) in destinations {
      var completions: [Bool] = []
      delegate.windowScene(scene, performActionFor: shortcut(action.rawValue)) { completions.append($0) }
      try check(completions == [true], "Known warm action did not complete exactly once with success")
      try check(store.withState { $0.pendingRoute == nil && $0.router.selectedTab == destination },
        "Warm action did not navigate to its destination")
    }
    try check(trace.invocationCount == 3, "Warm actions were dropped or delivered twice")
  }

  private static func unknownWarmAction(in scene: UIWindowScene) throws {
    let delegate = VroomSceneDelegate()
    let trace = Trace()
    let store = makeStore(trace)
    delegate.bindRootStore(store)
    store.send(.onAppear)
    store.send(.router(.selectTab(.categories)))
    var completions: [Bool] = []
    delegate.windowScene(scene, performActionFor: shortcut(HomeScreenQuickAction.settings.rawValue + ".extra")) {
      completions.append($0)
    }
    try check(completions == [false], "Unknown warm action did not complete exactly once with failure")
    try check(trace.invocationCount == 0 && store.withState { $0.router.selectedTab == .categories },
      "Unknown action changed navigation")
  }

  private static func betaDeferral(in scene: UIWindowScene) throws {
    UserDefaults.standard.set(false, forKey: betaSheetKey)
    let delegate = VroomSceneDelegate()
    let trace = Trace()
    let store = makeStore(trace)
    delegate.handleQuickAction(shortcut(HomeScreenQuickAction.settings.rawValue))
    delegate.bindRootStore(store)
    store.send(.onAppear)
    try check(store.withState {
      $0.isPresentingBetaSheet && $0.pendingRoute == .settings && $0.router.selectedTab == .home
    }, "Startup shortcut bypassed the beta sheet")
    var completions: [Bool] = []
    delegate.windowScene(scene, performActionFor: shortcut(HomeScreenQuickAction.categories.rawValue)) {
      completions.append($0)
    }
    try check(completions == [true] && store.withState {
      $0.isPresentingBetaSheet && $0.pendingRoute == .categories && $0.router.selectedTab == .home
    }, "Warm shortcut bypassed the beta sheet or failed to replace the queued destination")
    store.send(.setBetaSheet(false))
    delegate.bindRootStore(store)
    store.send(.setBetaSheet(false))
    try check(store.withState {
      !$0.isPresentingBetaSheet && $0.pendingRoute == nil && $0.router.selectedTab == .categories
    }, "Dismissing the beta sheet lost the requested destination")
    try check(trace.invocationCount == 2 && trace.navigationCount == 1,
      "The deferred action navigated more than once")
  }

  private static func delegateStoreIsolation() throws {
    let firstDelegate = VroomSceneDelegate()
    let secondDelegate = VroomSceneDelegate()
    let firstTrace = Trace()
    let secondTrace = Trace()
    let firstStore = makeStore(firstTrace)
    let secondStore = makeStore(secondTrace)
    firstDelegate.handleQuickAction(shortcut(HomeScreenQuickAction.settings.rawValue))
    secondDelegate.handleQuickAction(shortcut(HomeScreenQuickAction.categories.rawValue))
    secondDelegate.bindRootStore(secondStore)
    try check(firstTrace.invocationCount == 0, "Binding one scene consumed another scene's launch action")
    firstDelegate.bindRootStore(firstStore)
    firstStore.send(.onAppear)
    secondStore.send(.onAppear)
    try check(firstStore.withState { $0.router.selectedTab == .settings }
      && secondStore.withState { $0.router.selectedTab == .categories },
      "Scene delegates delivered to the wrong Root store")
    try check(firstTrace.invocationCount == 1 && secondTrace.invocationCount == 1,
      "One scene's launch action was dropped or duplicated")
  }
}
