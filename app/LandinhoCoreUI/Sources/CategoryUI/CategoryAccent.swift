import LandinhoFoundation
import SwiftUI

/// A category's exact identity color beside text that uses native foregrounds.
/// The name remains the identifier for people who cannot distinguish the colors.
public struct CategoryNameLabel: View {
  public init(category: RaceCategory) {
    self.category = category
  }

  let category: RaceCategory

  public var body: some View {
    HStack(spacing: 6) {
      CategoryColorSwatch(color: category.resolvedColor, size: 10)
        .accessibilityHidden(true)
      Text(category.title)
        .foregroundStyle(.primary)
    }
    .accessibilityElement(children: .combine)
  }
}

public extension View {
  /// Tint for borderless actions on native app surfaces. Identity markers use
  /// the original color; this adjustment is only for readable control content.
  func categoryAccent(_ color: CategoryColor) -> some View {
    modifier(CategoryAccentModifier(color: color))
  }
}

private struct CategoryAccentModifier: ViewModifier {
  let color: CategoryColor
  @Environment(\.colorScheme) var colorScheme

  func body(content: Content) -> some View {
    // Conservative reference surfaces for the current native app: light
    // secondary background and dark elevated background. This is not a
    // contrast guarantee for arbitrary images, materials or tinted fills.
    let surface = colorScheme == .dark
      ? CategoryColor(red: 44, green: 44, blue: 46)
      : CategoryColor(red: 242, green: 242, blue: 247)
    content.tint(color.readableAccent(on: surface).swiftUIColor)
  }
}
