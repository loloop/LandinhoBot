//
//  NotificationContainerView.swift
//
//
//  Created by Mauricio Cardozo on 14/08/23.
//

import Foundation
import SwiftUI

struct NotificationContainerView: View {
  let error: QueueableNotification
  var onDragEnd: () -> Void

  @State var offset = CGFloat(-30)
  @State var opacity = CGFloat(0)
  @State var xScale = CGFloat(1)
  @State var isExpanded = false

  public var body: some View {
    SwitchView(error: error)
    .font(.callout)
    .fontDesign(.rounded)
    .lineLimit(isExpanded ? nil : 3)
    .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
    .padding(.horizontal)
    .offset(y: offset)
    .opacity(opacity)
    .gesture(dismissGesture)
    .scaleEffect(x: xScale)
    .onAppear {
      withAnimation(.spring) {
        offset = 0
        opacity = 1
      }
    }
    .simultaneousGesture(
      TapGesture()
        .onEnded {
          withAnimation {
            isExpanded.toggle()
          }
        }
    )
  }

  var dismissGesture: some Gesture {
    #if (os(tvOS))
    // TODO: Add a dismiss timer for notifications when handling tvOS
    // currently this TapGesture won't work as I haven't found the correct way to make
    // the notification focusable by the remote, so we can't interact with it.
    TapGesture()
      .onEnded {
        onDragEnd()
      }
    #else
    DragGesture(
      minimumDistance: 0,
      coordinateSpace: .local)
      .onChanged{ value in
        if value.translation.height < 10 {
          offset = value.translation.height
          if value.translation.height > 0 {
            withAnimation(.interactiveSpring()) {
              xScale = 0.95
            }
          }
        }
        if offset < 0 {
          opacity = (value.translation.height/50) + 1
        }
      }
      .onEnded { value in
        if offset > 0 {
          withAnimation(.spring) {
            offset = 0
            xScale = 1
          }
        }

        if offset < 0 {
          onDragEnd()
        }
      }
    #endif
  }

  struct SwitchView: View {
    let error: QueueableNotification
    var body: some View {
      switch error.type {
      case .debug:
        DebugNotificationView(text: error.text)
      case .testflight:
        TestflightNotificationView(text: error.text)
      case .warning:
        WarningNotificationView(text: error.text)
      case .critical:
        CriticalNotificationView(text: error.text)
      case .success:
        SuccessNotificationView(text: error.text)
      }
    }
  }
}

#Preview {
  VStack {
    NotificationContainerView(error: .debug("Texto"), onDragEnd: { })
    NotificationContainerView(error: .testflight("Texto"), onDragEnd: { })
    NotificationContainerView(error: .warning("Texto"), onDragEnd: { })
    NotificationContainerView(error: .critical("Texto"), onDragEnd: { })
    NotificationContainerView(error: .success("Texto"), onDragEnd: { })
  }
}
