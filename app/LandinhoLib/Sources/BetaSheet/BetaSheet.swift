//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import Foundation
import SwiftUI

public struct BetaSheet: View {

  public init() {}

  @Environment(\.dismiss) var dismiss

  @State var isContinueEnabled: Bool = false

  public var body: some View {
    VStack {
      ScrollView {
        VStack(spacing: 30) {
          Image("AppIcon", bundle: .module)
            .resizable()
            .frame(width: 250, height: 250, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 35.0, style: .continuous))
            .padding(.top)

          Text("Bem vindo ao teste beta do VroomVroom!")
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .multilineTextAlignment(.center)

          TitleTextView(title: "Problemas conhecidos", text: issues)
          TitleTextView(title: "Adicionados na última atualização", text: latestRelease)
          TitleTextView(title: "Próximos passos", text: nextSteps)

          Text("Para ver esta tela novamente, clique em Changelog na tela de Ajustes. Esta tela também aparecerá sempre que uma versão nova do app for lançada.")
            .font(.headline)
            .padding(.horizontal)
            .onVisible {
              isContinueEnabled = true
            }
        }
      }

      Button(action: {
        dismiss()
      }, label: {
        Text("Continuar")
          .padding(.vertical, 5)
          .frame(maxWidth: .infinity)
      })
      .disabled(!isContinueEnabled)
      .buttonStyle(.borderedProminent)
      .padding([.horizontal, .bottom])
    }
  }

  struct TitleTextView: View {
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
      VStack(alignment: .leading) {
        Text(title)
          .font(.title3)
          .bold()
        Text(text)
          .font(.callout)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal)
    }
  }

  let issues: LocalizedStringKey = """
  • Design obviamente não está nem um pouco próximo de estar pronto
  • App não tem cache em nada. Tudo vai ser recarregado quando o app inicia
  • Erros atualmente mostram o payload completo do erro (Intencional, por enquanto)
  """

  let latestRelease: LocalizedStringKey = """
  01/10/2026
  • Protege a administração com senha do servidor; o acesso fica oculto no número da versão em Ajustes e é bloqueado ao sair ou colocar o app em segundo plano
  • Adiciona favoritos de categorias e uma Home com paginação, atualização e prioridade para categorias favoritas
  • Manutenção: mantém o acesso administrativo da versão Mock inteiramente em memória e adapta seus testes à nova Home
  • Manutenção: adiciona a versão VroomVroom Mock para testar o app sem servidor, com calendários de exemplo e alterações administrativas em memória
  • Manutenção: corrige a dependência de rede dos testes para impedir consultas à API real
  • Atualiza a programação da Fórmula 1 automaticamente a partir da fonte oficial, incluindo temporadas futuras já publicadas e testes de pré-temporada
  • Adiciona a tela Importações na administração → Fórmula 1 para configurar o intervalo de atualização e buscar a programação manualmente
  • Permite consultar o histórico de importações, comparar alterações, ver avisos e relacionar registros existentes
  • Mostra horários pendentes nos detalhes da corrida, nos widgets e no bot do Telegram, com acesso à programação oficial nos detalhes e no bot
  • Mostra as datas dos eventos principais e os horários no fuso do dispositivo, com as sessões em ordem cronológica
  • Identifica sessões canceladas, remove corridas canceladas da lista de próximos eventos e evita lembretes de eventos cancelados ou sem horário confirmado

  30/09/2026
  • Adiciona inscrições por categoria no bot do Telegram: /subscribe f1 para acompanhar, /unsubscribe f1 para cancelar e /mysubscriptions para ver suas inscrições
  • Adiciona lembretes no Telegram para os eventos das categorias acompanhadas nas próximas 24 horas e na próxima hora

  29/06/2024
  • Corrige a consulta da próxima corrida no bot do Telegram e mostra uma mensagem quando não encontra uma corrida

  27/06/2024
  • Adiciona uma versão experimental do app para Apple TV com a lista de próximas corridas
  • Atualiza dependências e reorganiza o código compartilhado entre o app e os widgets

  24/11/2023
  • Melhora o layout quando existe mais de um evento principal em uma corrida
  • Remove aquele monte de widgets da home por uma lista que faz um pouco mais de sentido
  • É possível compartilhar uma corrida a partir da Home agora
  • Simplifica o fluxo de compartilhar uma corrida
  • Adiciona a opção de remover sessões de treino de um Widget
  • Corrige a área de toque dos botões na tela de categorias
  • Ícone novo com tema de São Paulo

  22/11/2023
  • Corrige um crash quando o app troca de telas
  • Corrige um problema onde o botão de voltar na tela de compartilhar não aparece em iPhones de tela pequena

  21/11/2023
  • Essa tela!
  • Notificações de erro - Clica em "Termos de Serviço", "Sobre o Desenvolvedor" ou "Política de Privacidade" nos Ajustes pra testar
  • Ícone novo
  • Número da versão nos ajustes
  • A tela de categorias agora funciona! Não, ainda não dá pra favoritar.

  20/11/2023
  • WIP: É possível compartilhar uma imagem que tem os horários de uma corrida
  • WIP: Tela de detalhes de uma corrida

  Antes disso, não tava anotando a data 😂:
  • Home placeholder com visualização dos Widgets
  • Painel de administração
  • Widget pequeno, médio e grande
  """

  let nextSteps: LocalizedStringKey = """
  Esta lista será completamente limpa antes do lançamento público do aplicativo (em ordem de prioridade)

  • App Clip
    • Botão de compartilhar o app em Ajustes -> App Clip ou Link
  • Ações rápidas no ícone do aplicativo
  • Design final da Home, Tela de Corrida, Categorias, Ajustes, Compartilhar, etc para iOS e iPadOS
  • Widget extra-largo para iPads
  • Ícone de verdade desenhado por um ser humano e não a aberração atual
  • Compartilhar texto de uma corrida -> Estilo o bot

  Para o futuro:
  • Notificações no app quando eventos específicos forem começar
  • Enviar feedback de horário direto numa corrida
  • Pedir horário da próxima corrida para a Siri
  • Busca de Categorias
  • Easter egg com Live Activity na busca de Categorias -> Você poderá criar um lembrete para a tela de notificações a partir de uma busca
  • Suporte a mais de um fuso horário
  • App de visionOS
  • App de macOS
  • Widgets de Lock Screen
  • Widgets de watchOS
  • App de watchOS
  • Melhorar a versão experimental do app de tvOS
  """
}

#Preview {
  BetaSheet()
}

// https://stackoverflow.com/questions/60595900/how-to-check-if-a-view-is-displayed-on-the-screen-swift-5-and-swiftui
public extension View {
  func onVisible(perform action: @escaping () -> Void) -> some View {
    modifier(BecomingVisible(action: action))
  }
}

private struct BecomingVisible: ViewModifier {

  @State var action: (() -> Void)?

  func body(content: Content) -> some View {
    content.overlay {
      GeometryReader { proxy in
        Color.clear
          .preference(
            key: VisibleKey.self,
            // See discussion!
            value: UIScreen.main.bounds.intersects(proxy.frame(in: .global))
          )
          .onPreferenceChange(VisibleKey.self) { isVisible in
            guard isVisible, let action else { return }
            action()
            self.action = nil
          }
      }
    }
  }

  struct VisibleKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { }
  }
}
