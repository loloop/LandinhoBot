//
//  UploadRaceEventBundle.swift
//
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Foundation

public enum UploadRaceEventBundle: Equatable, CaseIterable, Identifiable {
  case F1Sprint
  case F1Regular

  var tag: String {
    switch self {
    case .F1Sprint, .F1Regular:
      "f1"
    }
  }

  var title: String {
    switch self {
    case .F1Regular: "fim de semana da F1"
    case .F1Sprint: "fim de semana Sprint da F1"
    }
  }

  public var id: String {
    title
  }

  var events: [UploadRaceEvent] {
    switch self {
    case .F1Sprint:
      [
        .init(title: "Treino Livre", date: Date(), isMainEvent: false),
        .init(title: "Classificação", date: Date(), isMainEvent: false),
        .init(title: "Sprint Shootout", date: Date(), isMainEvent: false),
        .init(title: "Sprint", date: Date(), isMainEvent: true),
        .init(title: "Corrida", date: Date(), isMainEvent: true),
      ]
    case .F1Regular:
      [
        .init(title: "Treino Livre  1", date: Date(), isMainEvent: false),
        .init(title: "Treino Livre 2", date: Date(), isMainEvent: false),
        .init(title: "Treino Livre 3", date: Date(), isMainEvent: false),
        .init(title: "Classificação", date: Date(), isMainEvent: false),
        .init(title: "Corrida", date: Date(), isMainEvent: true),
      ]
    }
  }
}
