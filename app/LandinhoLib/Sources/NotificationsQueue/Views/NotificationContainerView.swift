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
  }

  struct SwitchView: View {
    let error: QueueableNotification
    var body: some View {
      switch error.type {
      case .debug:
        DebugErrorView(text: error.text)
      case .testflight:
        TestflightErrorView(text: error.text)
      case .warning:
        WarningErrorView(text: error.text)
      case .critical:
        CriticalErrorView(text: error.text)
      }
    }
  }
}
