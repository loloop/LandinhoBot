//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import ComposableArchitecture
import Foundation

/*
 TODO:
 class AsyncLocationStream: NSObject, CLLocationManagerDelegate {
     lazy var stream: AsyncStream<CLLocation> = {
         AsyncStream { (continuation: AsyncStream<CLLocation>.Continuation) -> Void in
             self.continuation = continuation
         }
     }()
     var continuation: AsyncStream<CLLocation>.Continuation?

     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

         for location in locations {
             continuation?.yield(location)
         }
     }
 }
 */

public class NotificationQueueClient {

  init() {
    // TODO: UserDefaults should be injected
    UserDefaults.standard.register(
      defaults: [
        debugErrorKey: false,
        testflightErrorKey: true
      ])

    showsDebugErrors = UserDefaults.standard.bool(
      forKey: debugErrorKey)
    showsTestflightErrors = UserDefaults.standard.bool(
      forKey: testflightErrorKey)
  }

  let debugErrorKey = "me.mauriciocardozo.racing.vroomvroom.debugNotifications"
  let testflightErrorKey = "me.mauriciocardozo.racing.vroomvroom.testflightNotifications"

  public enum `Type` {
    case debug
    case testflight
    case warning
    case critical
    case success
  }

  lazy var observer: AsyncStream<QueueableNotification> = {
    return AsyncStream { [weak self] continuation in
      self?.sendError = {
        continuation.yield($0)
      }
    }
  }()

  var notificationQueue: [QueueableNotification] = [] {
    didSet {
      guard
        let latestError = notificationQueue.last,
        let sendError
      else {
        return
      }
      sendError(latestError)
    }
  }

  var sendError: ((QueueableNotification) -> Void)?

  @_spi(Internal) public var showsTestflightErrors = false {
    didSet {
      UserDefaults.standard.setValue(
        showsTestflightErrors, forKey: testflightErrorKey)
    }
  }

  @_spi(Internal) public var showsDebugErrors = false {
    didSet {
      UserDefaults.standard.setValue(
        showsDebugErrors, forKey: debugErrorKey)
    }
  }

  public func enqueue(_ error: QueueableNotification) {
    // TODO: OSLog these errors
    // TODO: Sleep a bit and then unfuck this logic

    if error.type == .debug {
      if showsDebugErrors {
        notificationQueue.append(error)
        return
      }
      return
    }

    if error.type == .testflight {
      if showsTestflightErrors {
        notificationQueue.append(error)
        return
      }
      return
    }

    notificationQueue.append(error)
  }
}

private enum NotificationQueueKey: DependencyKey {
  static var liveValue: NotificationQueueClient = NotificationQueueClient()
}

public extension DependencyValues {
  var notificationQueue: NotificationQueueClient {
    get { self[NotificationQueueKey.self] }
    set { self[NotificationQueueKey.self] = newValue }
  }
}
