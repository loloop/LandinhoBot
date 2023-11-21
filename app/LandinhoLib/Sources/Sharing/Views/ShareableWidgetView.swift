//
//  ShareableWidgetView.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

//import Common
//import Foundation
//import SwiftUI
//import WidgetUI
//
//struct ShareableWidgetView: View {
//  let type: ShareableWidgetType
//  let race: MegaRace
//
//  @Namespace var animation
//
//  var body: some View {
//    Group {
//      switch type {
//      case .systemMedium:
//        NextRaceMediumWidgetView(
//          bundle: race.bundled,
//          lastUpdatedDate: nil)
//        .matchedGeometryEffect(id: "widget", in: animation)
//      case .systemLarge:
//        NextRaceLargeWidgetView(
//          bundle: race.bundled,
//          lastUpdatedDate: nil)
//        .matchedGeometryEffect(id: "widget", in: animation)
//      }
//    }
//    .widgetBackground()
//    .widgetFrame(family: type.supportedFamily)
//  }
//}
