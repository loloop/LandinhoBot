import APIClient
import ComposableArchitecture
import Foundation
import SwiftUI

public struct ImportsAdminView: View {
  public init(store: StoreOf<ImportsAdmin>) { self.store = store }
  let store: StoreOf<ImportsAdmin>
  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Form {
        Section("Atualização automática") {
          if let settings = viewStore.settings.response.value {
            if settings.provider != nil {
              Toggle("Ativada", isOn: viewStore.$enabled)
              Stepper("A cada \(viewStore.intervalDays) dias", value: viewStore.$intervalDays, in: 1...365)
              Button("Salvar configuração") { viewStore.send(.saveSettings) }
              if let next = settings.nextImportAt { LabeledContent("Próxima atualização", value: next.formatted()) }
              Button("Atualizar agora", systemImage: "arrow.clockwise") { viewStore.send(.refreshNow) }
                .disabled(isBusy(viewStore.refresh.response) || isBusy(viewStore.match.response))
            } else {
              Text("Esta categoria ainda não tem uma integração automática.").foregroundStyle(.secondary)
            }
          } else if case .finished(.failure(let error)) = viewStore.settings.response {
            Text(error.localizedDescription).foregroundStyle(.red)
            Button("Tentar novamente") { viewStore.send(.onAppear) }
          } else { ProgressView() }
        }
        if isBusy(viewStore.refresh.response) { Section { ProgressView("Buscando programação oficial…") } }
        if case .finished(.failure(let error)) = viewStore.refresh.response {
          Section("Não foi possível atualizar") { Text(error.localizedDescription) }
        }
        if case .finished(.failure(let error)) = viewStore.match.response {
          Section("Não foi possível relacionar") { Text(error.localizedDescription) }
        }
        Section("Histórico de importações") {
          ForEach(viewStore.runs) { run in
            NavigationLink {
              ImportDetailView(run: run, matchState: viewStore.match.response) { index, candidate in viewStore.send(.resolveMatch(run.id, index, candidate.id)) }
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                Text(run.startedAt.formatted())
                Text("\(run.statusLabel) · \(run.changes.count) alterações · \(run.issues.count) avisos")
                  .font(.caption).foregroundStyle(.secondary)
              }
            }
          }
          if viewStore.runs.isEmpty { Text("Nenhuma importação registrada.").foregroundStyle(.secondary) }
          if viewStore.canLoadMore {
            Button("Carregar mais") { viewStore.send(.loadMore) }.disabled(isBusy(viewStore.history.response))
          }
          if case .finished(.failure(let error)) = viewStore.history.response {
            Text(error.localizedDescription).foregroundStyle(.red)
          }
        }
      }
      .navigationTitle("Importações · \(viewStore.title)")
      .task { viewStore.send(.onAppear) }
    }
  }
  private func isBusy<T: Equatable & Decodable>(_ state: APIRequestState<T>) -> Bool {
    switch state { case .loading, .reloading: return true; default: return false }
  }
}

private struct ImportDetailView: View {
  let run: ScheduleImport
  let matchState: APIRequestState<ImportSettings>
  let resolve: (Int, ScheduleImport.Candidate) -> Void
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    List {
      Section {
        LabeledContent("Resultado", value: run.statusLabel)
        LabeledContent("Início", value: run.startedAt.formatted())
        LabeledContent("Origem", value: run.trigger == "manual" ? "Atualização manual" : "Agendamento")
      }
      Section("Alterações publicadas") {
        if run.changes.isEmpty { Text("Nenhuma alteração publicada.").foregroundStyle(.secondary) }
        ForEach(Array(run.changes.enumerated()), id: \.offset) { _, change in
          VStack(alignment: .leading, spacing: 5) {
            Text(change.title).font(.headline)
            Text(change.fieldLabel).font(.caption).foregroundStyle(.secondary)
            Text("Antes: \(display(change.before, field: change.field))")
            Text("Depois: \(display(change.after, field: change.field))")
            if let value = change.sourceURL, let url = URL(string: value) { Link("Fonte oficial", destination: url) }
          }
        }
      }
      Section("Avisos") {
        if case .finished(.failure(let error)) = matchState {
          Text(error.localizedDescription).foregroundStyle(.red)
        }
        ForEach(Array(run.issues.enumerated()), id: \.offset) { index, issue in
          VStack(alignment: .leading, spacing: 6) {
            Text(issue.title).font(.headline)
            Text(issue.message).font(.callout)
            if let value = issue.sourceURL, let url = URL(string: value) { Link("Fonte oficial", destination: url) }
            ForEach(issue.candidates) { candidate in
              Button("Relacionar a \(candidate.title)") { resolve(index, candidate) }
                .disabled(matchState.isLoading)
            }
          }
        }
      }
    }
    .navigationTitle("Detalhes da importação")
    .onChange(of: matchState) { _, state in
      if case .finished(.success) = state { dismiss() }
    }
  }
  private func display(_ value: String?, field: String) -> String {
    guard let value else { return field == "date" ? "Horário pendente" : "—" }
    if let date = ISO8601DateFormatter().date(from: value) { return date.formatted() }
    if value == "true" { return "Sim" }
    if value == "false" { return "Não" }
    if value == "added" { return "Adicionado" }
    if value == "added (time pending)" { return "Adicionado com horário pendente" }
    return value
  }
}
