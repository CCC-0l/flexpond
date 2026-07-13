import SwiftUI
import FlexpondCore

/// Switches between the Workout tab's three screens, matching `AppViewModel.workoutScreen`.
struct WorkoutContainerView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        switch vm.workoutScreen {
        case .browse: WorkoutBrowseView(vm: vm)
        case .detail: WorkoutDetailView(vm: vm)
        case .today: WorkoutTodayView(vm: vm)
        }
    }
}
