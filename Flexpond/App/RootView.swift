import SwiftUI
import FlexpondCore

/// App shell: custom header + scrollable tab content + custom bottom tab
/// bar, matching the mockup's `IOSDevice` content area (the device bezel
/// itself is mockup-only chrome and isn't ported — see `FlexpondHeader`).
struct RootView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    content
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                }
            }

            FlexpondTabBar(selected: vm.selectedTab) { vm.selectTab($0) }
                .ignoresSafeArea(edges: .bottom)
        }
        .foregroundStyle(Theme.textPrimary)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var header: some View {
        switch vm.selectedTab {
        case .home:
            FlexpondHeader(title: AppTab.home.label)
        case .workout:
            FlexpondHeader(
                title: workoutTitle,
                showBack: vm.workoutScreen != .browse,
                backLabel: backLabel,
                onBack: vm.goBack
            )
        case .diet:
            FlexpondHeader(title: AppTab.diet.label)
        case .readiness:
            FlexpondHeader(title: AppTab.readiness.label)
        case .physique:
            FlexpondHeader(title: AppTab.physique.label)
        }
    }

    private var workoutTitle: String {
        switch vm.workoutScreen {
        case .browse: return "Workout"
        case .detail: return vm.selectedCategory?.displayName ?? "Workout"
        case .today: return "Today"
        }
    }

    private var backLabel: String {
        vm.workoutScreen == .today ? (vm.selectedCategory?.displayName ?? "Workout") : "Workout"
    }

    @ViewBuilder private var content: some View {
        switch vm.selectedTab {
        case .home: HomeView(vm: vm)
        case .workout: WorkoutContainerView(vm: vm)
        case .diet: DietContainerView(vm: vm)
        case .readiness: ReadinessView(vm: vm)
        case .physique: PhysiqueView(vm: vm)
        }
    }
}
