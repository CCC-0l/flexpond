import SwiftUI
import FlexpondCore

@main
struct FlexpondApp: App {
    @StateObject private var vm = AppViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(vm: vm)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                vm.refreshOuraIfConnected()
            }
        }
    }
}
