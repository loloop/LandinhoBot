import ComposableArchitecture
import Foundation

/// The same local favorites are used by Categories and the Home calendar.
public struct CategoryFavorites {
  public static let storageKey = "landinho.favorite-category-tags"
  public var read: () -> Set<String>
  public var write: (Set<String>) -> Void

  public init(read: @escaping () -> Set<String>, write: @escaping (Set<String>) -> Void) {
    self.read = read
    self.write = write
  }

  public init(defaults: UserDefaults) {
    self.init(
      read: { Set(defaults.stringArray(forKey: Self.storageKey) ?? []) },
      write: { defaults.set($0.sorted(), forKey: Self.storageKey) })
  }
}

extension CategoryFavorites: DependencyKey {
  public static let liveValue = Self(defaults: .standard)
  public static let testValue = Self(read: { [] }, write: { _ in })
}

public extension DependencyValues {
  var categoryFavorites: CategoryFavorites {
    get { self[CategoryFavorites.self] }
    set { self[CategoryFavorites.self] = newValue }
  }
}
