import Foundation
import CategoryUI
import LandinhoFoundation
import SwiftUI

public struct NextRaceExtraLargeWidgetView: View {
  public init(race: Race, lastUpdatedDate: Date?, referenceDate: Date? = nil, showNonMainEventSessions: Bool = true) {
    self.race = race
    self.lastUpdatedDate = lastUpdatedDate
    self.referenceDate = referenceDate
    self.showNonMainEventSessions = showNonMainEventSessions
  }

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  let race: Race
  let lastUpdatedDate: Date?
  let referenceDate: Date?
  let showNonMainEventSessions: Bool

  public var body: some View {
    GeometryReader { geometry in
      let rows = dynamicTypeSize.isAccessibilitySize ? 2 : (geometry.size.height >= 350 ? 4 : 3)
      let schedule = ExtraLargeWidgetSchedule(content: content, rowsPerColumn: rows)

      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .top, spacing: 24) {
          VStack(alignment: .leading, spacing: 5) {
            CategoryNameLabel(category: race.category)
              .font(.subheadline.weight(.semibold))
            Text(race.title)
              .font(.title2.weight(.bold))
              .lineLimit(2)
              .minimumScaleFactor(0.8)
          }
          Spacer(minLength: 0)
          Text("Horários locais")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        HStack(alignment: .top, spacing: 20) {
          nextSession(schedule.nextSession)
            .frame(width: geometry.size.width * 0.28, alignment: .leading)

          Divider()

          VStack(alignment: .leading, spacing: 8) {
            Text("Programação da etapa")
              .font(.subheadline.weight(.semibold))
            if let message = content.emptyMessage {
              Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else if schedule.columns.isEmpty {
              Text("Esta é a última sessão programada.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
              HStack(alignment: .top, spacing: 20) {
                ForEach(schedule.columns.indices, id: \.self) { index in
                  VStack(alignment: .leading, spacing: 10) {
                    ForEach(schedule.columns[index]) { session in
                      sessionRow(session)
                    }
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
              if schedule.hiddenSessionCount > 0 {
                Text("Mais \(schedule.hiddenSessionCount) sessões no app")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity, alignment: .top)

        footer
      }
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
      // A widget cannot scroll: keep its next start and footer inside the fixed footprint.
      .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
  }

  private func nextSession(_ session: RaceEvent?) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Próxima sessão")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      if let session {
        Text(session.title)
          .font(.title3.weight(.semibold))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
        Text(session.dayLabel)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Text(session.timeLabel)
          .font(session.date == nil ? .headline : .largeTitle.weight(.bold))
          .monospacedDigit()
          .lineLimit(2)
          .minimumScaleFactor(0.8)
      } else {
        Text("—")
          .font(.largeTitle)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private func sessionRow(_ session: RaceEvent) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      HStack(alignment: .firstTextBaseline, spacing: 5) {
        Text(session.dayLabel)
          .foregroundStyle(.secondary)
        Spacer(minLength: 0)
        Text(session.timeLabel)
          .fontWeight(.semibold)
          .monospacedDigit()
      }
      .font(.caption)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      Text(session.title)
        .font(.subheadline)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
    }
    .accessibilityElement(children: .combine)
  }

  private var footer: some View {
    VStack(alignment: .leading, spacing: 4) {
      if content.hasPendingTimes {
        Text("Horários pendentes. Consulte a programação oficial.")
      }
      HStack(spacing: 12) {
        Text("Fuso: \(TimeZone.current.identifier)")
        if let source = race.sourceURL, let host = URL(string: source)?.host {
          Text("Fonte: \(host)")
        }
        Spacer(minLength: 0)
        if let lastUpdatedDate {
          Text("Atualizado em: \(lastUpdatedDate.formatted(date: .omitted, time: .shortened))")
        }
      }
      .lineLimit(1)
      .minimumScaleFactor(0.8)
    }
    .font(.caption2)
    .foregroundStyle(.secondary)
  }

  private var content: WidgetScheduleContent {
    WidgetScheduleContent(race: race, referenceDate: referenceDate, showNonMainEventSessions: showNonMainEventSessions)
  }
}
