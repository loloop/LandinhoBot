import Foundation

/// An opaque sRGB category identity color, encoded as `#RRGGBB`.
public struct CategoryColor: Codable, Equatable, Hashable, Sendable {
  public let hex: String

  public init?(hex: String) {
    guard hex.utf8.count == 7, hex.first == "#",
      hex.dropFirst().utf8.allSatisfy({
        (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
      })
    else { return nil }
    self.hex = hex.uppercased()
  }

  public init(red: UInt8, green: UInt8, blue: UInt8) {
    hex = String(format: "#%02X%02X%02X", red, green, blue)
  }

  public var red: Double { component(shift: 16) }
  public var green: Double { component(shift: 8) }
  public var blue: Double { component(shift: 0) }

  /// Stable across launches and devices; Swift's randomized `hashValue` is unsuitable here.
  public static func fallback(for tag: String) -> Self {
    let palette: [Self] = [
      .init(red: 74, green: 111, blue: 165),
      .init(red: 181, green: 88, blue: 63),
      .init(red: 66, green: 133, blue: 110),
      .init(red: 134, green: 95, blue: 162),
      .init(red: 167, green: 118, blue: 37),
      .init(red: 49, green: 128, blue: 147),
    ]
    let hash = tag.lowercased().utf8.reduce(UInt32(2_166_136_261)) {
      ($0 ^ UInt32($1)) &* 16_777_619
    }
    return palette[Int(hash % UInt32(palette.count))]
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let hex = try container.decode(String.self)
    guard let color = Self(hex: hex) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected #RRGGBB")
    }
    self = color
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(hex)
  }

  private func component(shift: UInt32) -> Double {
    let rgb = UInt32(hex.dropFirst(), radix: 16)!
    return Double((rgb >> shift) & 0xFF) / 255
  }
}
