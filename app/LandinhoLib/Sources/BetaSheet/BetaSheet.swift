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
  • Eventos principais na tela de detalhe não tem informação da data
  • O botão de um Widget pequeno não está funcionando quando colocado na Home
  • Na home provisória, passar para o próximo evento de um widget pequeno afeta TODOS os widgets pequenos
  • Erros atualmente mostram o payload completo do erro (Intencional, por enquanto)
  """

  let latestRelease: LocalizedStringKey = """
  24/11
  • Melhora o layout quando existe mais de um evento principal em uma corrida
  • Remove aquele monte de widgets da home por uma lista que faz um pouco mais de sentido

  22/11
  • Corrige um crash quando o app troca de telas
  • Corrige um problema onde o botão de voltar na tela de compartilhar não aparece em iPhones de tela pequena

  21/11
  • Essa tela!
  • Notificações de erro - Clica em "Termos de Serviço", "Sobre o Desenvolvedor" ou "Política de Privacidade" nos Ajustes pra testar
  • Ícone novo
  • Número da versão nos ajustes
  • A tela de categorias agora funciona! Não, ainda não dá pra favoritar.

  20/11
  • WIP: É possível compartilhar uma imagem que tem os horários de uma corrida
  • WIP: Tela de detalhes de uma corrida

  Antes disso, não tava anotando a data 😂:
  • Home placeholder com visualização dos Widgets
  • Painel de administração
  • Widget pequeno, médio e grande
  """

  let nextSteps: LocalizedStringKey = """
  Esta lista será completamente limpa antes do lançamento público do aplicativo

  • Ícone de verdade desenhado por um ser humano e não a aberração atual
  • Compartilhar uma corrida direto da Home
  • Imagem de fundo ao compartilhar uma corrida por imagem
  • Opção de remover sessões de treino de um Widget pequeno
  • Compartilhar texto de uma corrida -> Estilo o bot
  • Botão de voltar tela será reposicionado na tela de compartilhar corrida
  • Parte de administração das categorias será escondida e protegida por senha
  • Adicionar cores para as categorias
  • O widget pequeno deixará de mostrar os horários de eventos que já se passaram (ex.: deixa de mostrar o treino livre se é a hora da classificação)
  • Categorias terão uma "accent color"
  • Home de verdade, com os horários de todas as categorias, categorias favoritas aparecendo primeiro e paginação
  • App Clip
  • Botão de compartilhar o app em Ajustes -> App Clip ou Link
  • Tela sobre o desenvolvedor
  • Ações rápidas no ícone do aplicativo
  • Design final da Home, Tela de Corrida, Categorias, Ajustes, Compartilhar, etc para iOS e iPadOS
  • Widget extra-largo para iPads

  Para o futuro:
  • Notificações quando eventos específicos forem começar
  • Enviar feedback de horário direto numa corrida
  • Pedir horário da próxima corrida para a Siri
  • Busca de Categorias
  • Easter egg com Live Activity na busca de Categorias -> Você poderá criar um lembrete para a tela de notificações a partir de uma busca
  • Suporte a Deep Links, para compartilhar o link de uma corrida - Leva para o CalendarioF1 se for F1
  • Suporte a mais de um fuso horário
  • App de visionOS
  • App de macOS
  • Widgets de Lock Screen
  • Widgets de watchOS
  • App de watchOS
  • App de tvOS
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
