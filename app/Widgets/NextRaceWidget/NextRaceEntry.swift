//
//  NextRaceEntry.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import Foundation
import WidgetKit
import ScheduleList

struct NextRaceEntry: TimelineEntry {
  var date: Date
  var response: ScheduleList.ScheduleListResponse?
}
