//
//  AppIntent.swift
//  Widgets
//
//  Created by Mauricio Cardozo on 15/11/23.
//

import WidgetKit
import AppIntents

struct NextRaceConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuração da Próxima Corrida"
    static var description = IntentDescription("Configura o widget")

    // TODO: Filter non main event sections
//    @Parameter(title: "Mostrar Treinos (Não funciona ainda)", default: true)
//    var showNonMainEventSessions: Bool
}
