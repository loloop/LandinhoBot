import LandinhoFoundation
import SwiftUI

struct RoundShareMenu: View {
  let race: Race
  let onShareImage: () -> Void

  var body: some View {
    Menu {
      RoundShareActions(race: race, onShareImage: onShareImage)
    } label: {
      Label("Compartilhar", systemImage: "square.and.arrow.up")
    }
  }
}

struct RoundShareActions: View {
  let race: Race
  let onShareImage: () -> Void

  var body: some View {
    ShareLink(item: RoundScheduleText.format(race: race)) {
      Label("Compartilhar texto", systemImage: "text.alignleft")
    }
    ShareLink(item: race.roundLinkShareText) {
      Label("Compartilhar link", systemImage: "link")
    }
    Button("Compartilhar imagem", systemImage: "photo", action: onShareImage)
  }
}
