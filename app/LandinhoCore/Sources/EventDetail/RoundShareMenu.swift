import LandinhoFoundation
import SwiftUI

struct RoundShareMenu: View {
  let race: Race
  let onShareImage: () -> Void

  var body: some View {
    Menu {
      ShareLink(item: RoundScheduleText.format(race: race)) {
        Label("Compartilhar texto", systemImage: "text.alignleft")
      }
      ShareLink(item: race.roundLinkShareText) {
        Label("Compartilhar link", systemImage: "link")
      }
      Button("Compartilhar imagem", systemImage: "photo", action: onShareImage)
    } label: {
      Label("Compartilhar", systemImage: "square.and.arrow.up")
    }
  }
}
