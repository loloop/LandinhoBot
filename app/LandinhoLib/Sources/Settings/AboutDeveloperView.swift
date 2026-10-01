import SwiftUI

struct AboutDeveloperView: View {
  var body: some View {
    List {
      Section {
        VStack(spacing: 12) {
          Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 72))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.tint)
            .accessibilityHidden(true)

          VStack(spacing: 4) {
            Text("Mauricio Cardozo")
              .font(.title2.bold())
            Text("Desenvolvedor do VroomVroom")
              .font(.subheadline)
              .foregroundStyle(.secondary)
            Text("@loloop")
              .font(.subheadline.monospaced())
              .foregroundStyle(.secondary)
              .accessibilityLabel("Usuário no GitHub: loloop")
          }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
      }

      Section("No GitHub") {
        Link(destination: URL(string: "https://github.com/loloop")!) {
          DeveloperLinkLabel(
            title: "Perfil do desenvolvedor",
            subtitle: "loloop",
            systemImage: "person.crop.circle")
        }
        .accessibilityHint("Abre o perfil de Mauricio Cardozo no GitHub")

        Link(destination: URL(string: "https://github.com/loloop/LandinhoBot")!) {
          DeveloperLinkLabel(
            title: "Código do projeto",
            subtitle: "LandinhoBot",
            systemImage: "chevron.left.forwardslash.chevron.right")
        }
        .accessibilityHint("Abre o repositório do VroomVroom no GitHub")
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Sobre o desenvolvedor")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct DeveloperLinkLabel: View {
  let title: LocalizedStringKey
  let subtitle: String
  let systemImage: String

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: systemImage)
        .font(.title2)
        .foregroundStyle(.tint)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(Color.secondary)
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)

      Image(systemName: "arrow.up.right")
        .font(.footnote)
        .foregroundStyle(Color.secondary)
        .accessibilityHidden(true)
    }
    .foregroundStyle(Color.primary)
    .padding(.vertical, 6)
  }
}

#Preview {
  NavigationStack {
    AboutDeveloperView()
  }
}
