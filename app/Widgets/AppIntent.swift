//
//  AppIntent.swift
//  Widgets
//
//  Created by Mauricio Cardozo on 15/11/23.
//

import WidgetKit
import AppIntents

struct NextRaceConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Configuração do widget Próxima Corrida"
  static var description = IntentDescription("Configura o widget")

  @Parameter(title: "Mostrar Treinos", default: true)
  var showNonMainEventSessions: Bool
}
