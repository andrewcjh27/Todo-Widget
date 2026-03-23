import SwiftUI

@main
struct TodoWidgetApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        MenuBarExtra("Todo", systemImage: "checklist") {
            TodoListView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}
