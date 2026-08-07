import SwiftUI
import FlexpondCore

struct DietDashboardView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DietHistorySegmentedControl(vm: vm)

            switch vm.dietHistoryMode {
            case .today: TodayContent(vm: vm)
            case .trends: DietTrendsView(vm: vm)
            }
        }
        .padding(.top, 6)
    }
}

private struct DietHistorySegmentedControl: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        HStack(spacing: 4) {
            segment("Today", isSelected: vm.dietHistoryMode == .today) { vm.setDietHistoryMode(.today) }
            segment("Trends", isSelected: vm.dietHistoryMode == .trends) { vm.setDietHistoryMode(.trends) }
        }
        .padding(4)
        .cardBackground(radius: 13)
    }

    private func segment(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? Theme.accentText : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct TodayContent: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            CalorieSummary(vm: vm)
            MacroBars(vm: vm)
            FoodLibraryRow(vm: vm)
            MealTimeline(vm: vm)
            LogMealForm(vm: vm)
        }
    }
}

private struct CalorieSummary: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                CircularRing(progress: vm.dietSummary.calorieProgress, lineWidth: 12)
                VStack(spacing: 5) {
                    Text("\(vm.dietSummary.remainingCalories)")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text("CAL REMAINING")
                        .font(.label(9))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(width: 158, height: 158)

            Text("\(vm.dietSummary.consumedCalories) of \(vm.dietSummary.targetCalories) cal today")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            Button("Edit profile") { vm.editDietProfile() }
                .font(.label(11))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
}

