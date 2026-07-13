import SwiftUI
import FlexpondCore

struct DietDashboardView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            CalorieSummary(vm: vm)
            MacroBars(vm: vm)
            QuickAddRow(vm: vm)
            MealLogSection(vm: vm)
            LogMealForm(vm: vm)
        }
        .padding(.top, 6)
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

private struct MacroBars: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 12) {
            macroBar(title: "Protein", consumed: vm.dietSummary.proteinConsumed, target: vm.dietSummary.proteinTarget, progress: vm.dietSummary.proteinProgress, color: Theme.accent)
            macroBar(title: "Carbs", consumed: vm.dietSummary.carbConsumed, target: vm.dietSummary.carbTarget, progress: vm.dietSummary.carbProgress, color: Theme.good)
            macroBar(title: "Fat", consumed: vm.dietSummary.fatConsumed, target: vm.dietSummary.fatTarget, progress: vm.dietSummary.fatProgress, color: Theme.warning)
        }
    }

    private func macroBar(title: String, consumed: Int, target: Int, progress: Double, color: Color) -> some View {
        VStack(spacing: 9) {
            HStack {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(consumed)g / \(target)g")
                    .font(.label(11.5))
                    .foregroundStyle(Theme.textSecondary)
            }
            GeometryReader { geo in
                Capsule().fill(Color.white.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color).frame(width: geo.size.width * progress)
                    }
            }
            .frame(height: 7)
        }
        .padding(13)
        .cardBackground(radius: 14)
    }
}

private struct QuickAddRow: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Quick add", count: nil)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuickMeal.presets) { meal in
                        Button { vm.addQuickMeal(meal) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(meal.name)
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Text("\(meal.calories) cal")
                                    .font(.label(10.5))
                                    .foregroundStyle(Theme.accent)
                            }
                            .frame(width: 128, alignment: .leading)
                            .padding(12)
                            .cardBackground(radius: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct MealLogSection: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Today's log", count: nil)
            if vm.mealLog.isEmpty {
                Text("Nothing logged yet today.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .cardBackground(radius: 14)
            } else {
                ForEach(vm.mealLog) { meal in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(meal.name)
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(meal.proteinGrams)g P · \(meal.carbGrams)g C · \(meal.fatGrams)g F")
                                .font(.label(10.5))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                        Text("\(meal.calories) cal")
                            .font(.label(13))
                            .foregroundStyle(Theme.accent)
                        Button { vm.removeMeal(meal.id) } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .cardBackground(radius: 14)
                }
            }
        }
    }
}

private struct LogMealForm: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Log a meal", count: nil)
            VStack(spacing: 9) {
                TextField("Meal name", text: $vm.newMealName)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(11)
                    .background(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.hairline, lineWidth: 1))

                HStack(spacing: 8) {
                    macroInput("Cal", text: $vm.newMealCalories)
                    macroInput("P (g)", text: $vm.newMealProtein)
                    macroInput("C (g)", text: $vm.newMealCarb)
                    macroInput("F (g)", text: $vm.newMealFat)
                }

                Button {
                    vm.addCustomMeal()
                } label: {
                    Text("Add to log")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(vm.canAddCustomMeal ? Theme.accentText : Theme.textFaint)
                        .background(vm.canAddCustomMeal ? Theme.accent : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!vm.canAddCustomMeal)
            }
            .padding(14)
            .cardBackground(radius: 16)
        }
    }

    private func macroInput(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 13))
            .foregroundStyle(Theme.textPrimary)
            .padding(.vertical, 10)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
    }
}
