import SwiftUI
import FlexpondCore

@main
struct FlexpondApp: App {
    @StateObject private var vm = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(vm: vm)
        }
    }
}
