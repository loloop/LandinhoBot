import Foundation

public extension CategoryColor {
  /// WCAG sRGB contrast ratio for two opaque colors.
  func contrastRatio(with other: Self) -> Double {
    let first = relativeLuminance
    let second = other.relativeLuminance
    return (max(first, second) + 0.05) / (min(first, second) + 0.05)
  }

  /// Keeps the identity color when readable; otherwise mixes toward black or
  /// white until its contrast against the supplied surface reaches 4.5:1.
  /// The stored color and decorative identity markers remain unchanged.
  func readableAccent(on background: Self) -> Self {
    guard contrastRatio(with: background) < 4.5 else { return self }
    let black = Self(red: 0, green: 0, blue: 0)
    let white = Self(red: 255, green: 255, blue: 255)
    let target = black.contrastRatio(with: background) > white.contrastRatio(with: background)
      ? black : white
    var lower = 0.0
    var upper = 1.0
    var result = target
    // Test quantized RGB candidates, so rounding never drops below the threshold.
    for _ in 0..<16 {
      let amount = (lower + upper) / 2
      let candidate = mixed(with: target, amount: amount)
      if candidate.contrastRatio(with: background) >= 4.5 {
        result = candidate
        upper = amount
      } else {
        lower = amount
      }
    }
    return result
  }

  private var relativeLuminance: Double {
    func linear(_ component: Double) -> Double {
      component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
  }

  private func mixed(with target: Self, amount: Double) -> Self {
    func component(_ start: Double, _ end: Double) -> UInt8 {
      UInt8(((start + (end - start) * amount) * 255).rounded())
    }
    return Self(
      red: component(red, target.red),
      green: component(green, target.green),
      blue: component(blue, target.blue))
  }
}
