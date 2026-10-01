// Reproduction-only app entry. The capture script temporarily substitutes this
// for VroomVroomApp.swift; it is not compiled into the shipping app.
import Categories
import CategoriesAdmin
import ComposableArchitecture
import LandinhoFoundation
import SwiftUI

@main
struct CategoryColorEvidenceApp: App {
  static let categories = try! JSONDecoder().decode([RaceCategory].self, from: Data(##"""
  [
    {"id":"f1","title":"Formula 1","tag":"f1","comment":"Calendário oficial","color":"#E34B43"},
    {"id":"stock","title":"Stock Car Brasil","tag":"stock-car","comment":"Calendário nacional","color":"#3C9672"},
    {"id":"formula-e","title":"Formula E","tag":"formula-e","comment":"Categoria sem cor definida"}
  ]
  """##.utf8))

  var body: some Scene {
    WindowGroup {
      if ProcessInfo.processInfo.arguments.contains("editor") {
        CategoryEditorView(store: Store(initialState: CategoryEditor.State(category: Self.categories[0])) {
          CategoryEditor()
        })
        .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("dark") ? .dark : .light)
      } else {
        NavigationStack {
          CategoriesView(store: Store(initialState: Self.categoriesState) { Categories() })
            .navigationTitle("Categorias")
        }
        .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("dark") ? .dark : .light)
      }
    }
  }

  static var categoriesState: Categories.State {
    var state = Categories.State()
    state.categoriesState.response = .finished(.success(categories))
    return state
  }
}
