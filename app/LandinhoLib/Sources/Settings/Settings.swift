//
//  Settings.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import Admin
import APIClient
import AppIntents
import BetaSheet
import Foundation
import ComposableArchitecture
import NotificationsQueue
import LandinhoFoundation
import SwiftUI

@Reducer
public struct Settings {
  public init() {}

  public struct State: Equatable {
    public init() {}

    @PresentationState var adminState: Admin.State?
    var isPasswordPromptPresented = false
    var isUnlocking = false
    var passwordError: String?
  }

  public enum Action: Equatable {
    case showPasswordPrompt
    case unlockAdmin(String)
    case unlockResponse(TaskResult<Bool>)
    case passwordPromptDismissed
    case lockAdmin
    case adminAccessRevoked
    case admin(PresentationAction<Admin.Action>)
  }

  @Dependency(\.adminAccess) var adminAccess
  private enum CancelID { case unlock }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .showPasswordPrompt:
        state.isPasswordPromptPresented = true
        state.passwordError = nil
        return .none

      case .unlockAdmin(let password):
        guard state.isPasswordPromptPresented, !state.isUnlocking, !password.isEmpty else { return .none }
        state.isUnlocking = true
        state.passwordError = nil
        return .run { send in
          await send(.unlockResponse(TaskResult {
            try await adminAccess.unlock(password)
            return true
          }))
        }
        .cancellable(id: CancelID.unlock, cancelInFlight: true)

      case .unlockResponse(.success):
        guard state.isUnlocking else { return .none }
        state.isUnlocking = false
        state.isPasswordPromptPresented = false
        state.adminState = .init()
        return .none

      case .unlockResponse(.failure(let error)):
        guard state.isUnlocking else { return .none }
        state.isUnlocking = false
        let error = error as NSError
        if error.domain == "LandinhoAPI", error.code == 401 {
          state.passwordError = "Senha incorreta. Tente novamente."
        } else if error.domain == "LandinhoAPI", error.code == 503 {
          state.passwordError = "A administração está indisponível. Contate o responsável pelo servidor."
        } else {
          state.passwordError = "Não foi possível verificar a senha. Confira sua conexão e tente novamente."
        }
        return .none

      case .passwordPromptDismissed:
        guard state.adminState == nil else { return .none }
        fallthrough
      case .lockAdmin, .admin(.dismiss):
        adminAccess.lock()
        fallthrough
      case .adminAccessRevoked:
        state.adminState = nil
        state.isPasswordPromptPresented = false
        state.isUnlocking = false
        state.passwordError = nil
        return .cancel(id: CancelID.unlock)

      case .admin:
        return .none
      }
    }
    .ifLet(\.$adminState, action: \.admin) {
      Admin()
    }
  }
}

public struct SettingsView: View {
  public init(store: StoreOf<Settings>) {
    self.store = store
  }

  let store: StoreOf<Settings>

  @Dependency(\.notificationQueue) var notificationQueue
  @Environment(\.scenePhase) var scenePhase

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      List {
        Section {
          ShareLink(item: AppSharing(bundle: .main).shareText) {
            Label("Compartilhar o app", systemImage: "square.and.arrow.up")
          }
        } footer: {
          Text(AppSharing(bundle: .main).explanation)
        }

        Section {
          ShortcutsLink()
        } header: {
          Text("Siri e Atalhos")
        } footer: {
          Text("Pergunte: “Quando é a próxima corrida no VroomVroom?” Você também pode consultar a próxima sessão ou escolher uma categoria nos Atalhos. Horários no fuso do aparelho. Requer conexão.")
        }

        NavigationLink {
          BetaSheet()
        } label: {
          Label("Changelog", systemImage: "tree")
        }

        Button {
          // TODO: Link terms of service
          notificationQueue.enqueue(.critical("Ainda não amigo"))
        } label: {
          Label("Termos de Serviço", systemImage: "book.closed")
        }

        Button {
          // TODO: Link privacy policy
          notificationQueue.enqueue(.warning("Ainda não amigo"))
        } label: {
          Label("Política de privacidade", systemImage: "lock")
        }

        NavigationLink {
          AboutDeveloperView()
        } label: {
          Label("Sobre o desenvolvedor", systemImage: "person")
        }

        if
          let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
          let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
          HStack {
            Text("Versão")
            Spacer()
            Text("\(version) (\(buildNumber))")
          }
          .contentShape(Rectangle())
          .onLongPressGesture(minimumDuration: 1.5) {
            store.send(.showPasswordPrompt)
          }
          .accessibilityElement(children: .combine)
          .accessibilityAction(named: Text("Abrir administração")) {
            store.send(.showPasswordPrompt)
          }
        }
      }
      .navigationTitle("Ajustes")
      .navigationDestination(store: store.scope(
        state: \.$adminState,
        action: { .admin($0) } )
      ) { store in
        AdminView(store: store)
          .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
              Button("Bloquear", systemImage: "lock.fill") {
                self.store.send(.lockAdmin)
              }
            }
          }
      }
      .sheet(isPresented: viewStore.binding(
        get: \.isPasswordPromptPresented,
        send: { $0 ? .showPasswordPrompt : .passwordPromptDismissed }
      )) {
        AdminPasswordView(store: store)
      }
      .onChange(of: scenePhase) { _, phase in
        if phase == .background { store.send(.lockAdmin) }
      }
      .onReceive(NotificationCenter.default.publisher(for: .landinhoAdminLocked).receive(on: RunLoop.main)) { _ in
        store.send(.adminAccessRevoked)
      }
    }
  }
}

private struct AdminPasswordView: View {
  let store: StoreOf<Settings>
  @State private var password = ""
  @FocusState private var isPasswordFocused: Bool

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        Form {
          Section {
            SecureField("Senha de administração", text: $password)
              .focused($isPasswordFocused)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .submitLabel(.go)
              .onSubmit { unlock() }
              .disabled(viewStore.isUnlocking)
            if let error = viewStore.passwordError {
              Text(error)
                .foregroundStyle(.red)
                .accessibilityLabel("Erro: \(error)")
            }
            Button(action: unlock) {
              HStack {
                Text(viewStore.isUnlocking ? "Verificando…" : "Desbloquear")
                Spacer()
                if viewStore.isUnlocking { ProgressView() }
              }
            }
            .disabled(password.isEmpty || viewStore.isUnlocking)
          } header: {
            Text("Acesso restrito")
          } footer: {
            Text("A senha é verificada pelo servidor. O acesso é encerrado ao bloquear ou sair do app.")
          }
        }
        .navigationTitle("Administração")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancelar") { store.send(.lockAdmin) }
          }
        }
        .onAppear { isPasswordFocused = true }
      }
    }
  }

  private func unlock() {
    guard !password.isEmpty else { return }
    store.send(.unlockAdmin(password))
    password = ""
    isPasswordFocused = false
  }
}

#Preview {
  SettingsView(store: .init(initialState: .init(), reducer: {
    Settings()
  }))
}
