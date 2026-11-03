import SwiftUI

@main
struct IhyaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Bugün", systemImage: "sun.max") { Text("İhya") }
            Tab("Odak", systemImage: "leaf") { Text("Odak") }
            Tab("Bahçe", systemImage: "tree") { Text("Bahçe") }
            Tab("Zikir", systemImage: "circle.dotted") { Text("Zikir") }
            Tab("Kitaplık", systemImage: "books.vertical") { Text("Kitaplık") }
        }
    }
}
