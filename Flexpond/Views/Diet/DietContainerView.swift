import SwiftUI
import FlexpondCore

struct DietContainerView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        switch vm.dietScreen {
        case .setup: DietSetupView(vm: vm)
        case .dashboard: DietDashboardView(vm: vm)
        }
    }
}
