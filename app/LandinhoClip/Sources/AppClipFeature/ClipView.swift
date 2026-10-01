#if os(iOS)
import LandinhoFoundation
import StoreKit
import SwiftUI

public struct ClipView: View {
  @ObservedObject private var model: ClipModel
  @Environment(\.openURL) private var openURL
  @State private var isStoreOverlayPresented = false
  private let sharing: AppSharing
  private let lime = Color(red: 0.75, green: 0.94, blue: 0.24)

  public init(model: ClipModel, sharing: AppSharing = .init(bundle: .main)) {
    self.model = model
    self.sharing = sharing
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          HStack(spacing: 12) {
            Image(systemName: "flag.checkered")
              .font(.title)
              .foregroundStyle(lime)
            VStack(alignment: .leading, spacing: 3) {
              Text("VROOMVROOM").font(.headline).tracking(2)
              Text("Horários do automobilismo").font(.subheadline).foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 8)

          if let notice = model.navigation.notice {
            Label(notice, systemImage: "info.circle")
              .font(.subheadline)
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
          }

          content

          VStack(alignment: .leading, spacing: 12) {
            Text("Continue no VroomVroom").font(.headline)
            Text("Favorite suas categorias e acompanhe o calendário completo.")
              .font(.subheadline).foregroundStyle(.secondary)
            Button {
              model.openFullApp { url, completion in openURL(url, completion: completion) }
            } label: {
              Label("Abrir app instalado", systemImage: "arrow.up.forward.app")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(lime)
            .foregroundStyle(.black)
            if sharing.appStoreURL != nil {
              Button("Obter app completo") { isStoreOverlayPresented = true }
                .frame(maxWidth: .infinity)
            } else {
              Link("Conhecer o projeto VroomVroom", destination: AppSharing.projectURL)
                .font(.subheadline)
            }
          }
          .padding()
          .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding()
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button("Próximas etapas", systemImage: "flag.checkered") { model.navigate(to: .home) }
            Button("Categorias", systemImage: "list.bullet") { model.navigate(to: .categories) }
          } label: {
            Image(systemName: "line.3.horizontal.decrease")
              .accessibilityLabel("Navegar pelo calendário")
          }
        }
      }
      .refreshable { await model.reload() }
      .task(id: model.navigation.revision) { await model.reload() }
      .alert("O app completo não está instalado", isPresented: $model.isAppUnavailable) {
        if let appStoreURL = sharing.appStoreURL { Link("Ver na App Store", destination: appStoreURL) }
        Button("Continuar no App Clip", role: .cancel) {}
      } message: {
        Text("Você pode continuar consultando os horários aqui.")
      }
      .appStoreOverlay(isPresented: $isStoreOverlayPresented) { _ in
        SKOverlay.AppClipConfiguration(position: .bottom)
      }
    }
  }

  private var title: String {
    switch model.navigation.destination {
    case .categories: return "Categorias"
    case .category(let tag): return "Calendário · " + tag.uppercased()
    case .round: return "Horários da etapa"
    default: return "Próximas etapas"
    }
  }

  @ViewBuilder private var content: some View {
    switch model.content {
    case .loading:
      ProgressView("Carregando horários…").frame(maxWidth: .infinity).padding(.vertical, 40)
    case .failure(let message):
      ContentUnavailableView {
        Label("Horários indisponíveis", systemImage: "wifi.exclamationmark")
      } description: { Text(message) } actions: {
        Button("Tentar novamente") { Task { await model.reload() } }
        Button("Ver próximas etapas") { model.navigate(to: .home) }
      }
    case .categories(let categories):
      if categories.isEmpty {
        ContentUnavailableView("Nenhuma categoria disponível", systemImage: "flag.checkered")
      } else {
        ForEach(categories) { category in
          Button { model.navigate(to: .category(tag: category.tag)) } label: {
            HStack {
              Text(category.title).font(.headline)
              Spacer()
              Image(systemName: "chevron.right")
            }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
          }.buttonStyle(.plain)
        }
      }
    case .rounds(let rounds):
      if rounds.isEmpty {
        ContentUnavailableView("Nenhuma etapa disponível", systemImage: "flag.checkered",
          description: Text("Escolha outra categoria ou consulte o calendário completo no app."))
        Button("Escolher categoria") { model.navigate(to: .categories) }
      } else {
        ForEach(rounds) { round in
          Button { model.navigate(to: .round(id: round.id)) } label: {
            VStack(alignment: .leading, spacing: 8) {
              Text(round.category.title).font(.caption).foregroundStyle(.secondary)
              HStack {
                Text(round.shortTitle).font(.title3.bold())
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(lime)
              }
              if let session = WidgetSessionSchedule(race: round, date: Date()).sessions.first {
                Text("\(session.title) · \(session.dayLabel) · \(session.timeLabel)")
                  .font(.subheadline).foregroundStyle(.secondary)
              } else { Text("Horários pendentes").font(.subheadline).foregroundStyle(.secondary) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
          }.buttonStyle(.plain)
        }
        Text("Prévia das próximas 5 etapas. Horários no fuso do dispositivo.")
          .font(.caption).foregroundStyle(.secondary)
      }
    case .round(let round):
      VStack(alignment: .leading, spacing: 16) {
        Text(round.category.title).font(.subheadline).foregroundStyle(.secondary)
        Text(round.shortTitle).font(.largeTitle.bold())
        if round.isCancelled {
          Label("Etapa cancelada", systemImage: "xmark.circle").foregroundStyle(.secondary)
        } else if round.events.isEmpty {
          Text("Os horários desta etapa ainda não foram publicados.").foregroundStyle(.secondary)
        }
        ForEach(round.events) { session in
          HStack(alignment: .top) {
            Text(session.title).fontWeight(session.isMainEvent ? .bold : .regular)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
              Text(session.timeLabel).fontWeight(session.isMainEvent ? .bold : .regular)
              Text(session.dayLabel).font(.caption).foregroundStyle(.secondary)
            }
          }
          .accessibilityElement(children: .combine)
          if session.id != round.events.last?.id { Divider() }
        }
        Text("Horários no fuso do dispositivo.").font(.caption).foregroundStyle(.secondary)
      }
      .padding()
      .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
  }
}
#endif
