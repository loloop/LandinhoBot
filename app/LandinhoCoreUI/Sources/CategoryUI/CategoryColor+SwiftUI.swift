import LandinhoFoundation
import SwiftUI

public extension CategoryColor {
  var swiftUIColor: Color {
    Color(.sRGB, red: red, green: green, blue: blue)
  }
}

/// A bordered identity marker stays visible even for white or black category colors.
public struct CategoryColorSwatch: View {
  public init(color: CategoryColor, size: CGFloat = 16) {
    self.color = color
    self.size = size
  }

  let color: CategoryColor
  let size: CGFloat

  public var body: some View {
    Circle()
      .fill(color.swiftUIColor)
      .overlay { Circle().strokeBorder(.primary.opacity(0.3), lineWidth: 1) }
      .frame(width: size, height: size)
      .accessibilityLabel("Cor da categoria")
      .accessibilityValue(color.hex)
  }
}
