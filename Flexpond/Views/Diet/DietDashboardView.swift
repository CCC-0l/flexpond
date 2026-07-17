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

private struct FoodLibraryRow: View {
    @ObservedObject var vm: AppViewModel
    @State private var searchText = ""

    private var filteredFoods: [SavedFood] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return vm.savedFoods }
        return vm.savedFoods.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Your food library", count: nil)

            TextField("Search your foods", text: $searchText)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary)
                .padding(10)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.hairline, lineWidth: 1))

            if filteredFoods.isEmpty {
                Text(vm.savedFoods.isEmpty ? "Log a custom meal below to start building your library." : "No foods match \"\(searchText)\".")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filteredFoods) { food in
                            FoodLibraryCard(food: food, onLog: { vm.logSavedFood(food) }, onDelete: { vm.deleteSavedFood(food.id) })
                        }
                    }
                    .padding(.top, 6) // room for the delete badge to overflow the card
                }
            }
        }
    }
}

private struct FoodLibraryCard: View {
    var food: SavedFood
    var onLog: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Button(action: onLog) {
            VStack(alignment: .leading, spacing: 6) {
                Text(food.name)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(food.calories) cal")
                    .font(.label(10.5))
                    .foregroundStyle(Theme.accent)
            }
            .frame(width: 128, alignment: .leading)
            .padding(12)
            .cardBackground(radius: 14)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textTertiary)
                    .background(Circle().fill(Theme.background))
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
    }
}

/// Today's meals as a single chronological list, timestamped by when each
/// was logged — no fixed Breakfast/Lunch/Dinner/Snack buckets, since a
/// 6-small-meals split (common for bodybuilders) doesn't map cleanly onto
/// 4 slots. Tapping a row opens it for editing.
private struct MealTimeline: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Today's meals", count: vm.todaysMealTimeline.count)

            if vm.todaysMealTimeline.isEmpty {
                Text("Nothing logged yet today.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .cardBackground(radius: 14)
            } else {
                ForEach(vm.todaysMealTimeline) { meal in
                    MealRow(meal: meal, onEdit: { vm.beginEditingMeal(meal.id) }, onRemove: { vm.removeMeal(meal.id) })
                }
            }
        }
    }
}

private struct MealRow: View {
    var meal: MealEntry
    var onEdit: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(meal.date.formatted(date: .omitted, time: .shortened))
                            .font(.label(10))
                            .foregroundStyle(Theme.textFaint)
                        Text(meal.name)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text("\(meal.proteinGrams)g P · \(meal.carbGrams)g C · \(meal.fatGrams)g F")
                        .font(.label(10.5))
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Text("\(meal.calories) cal")
                .font(.label(13))
                .foregroundStyle(Theme.accent)
            Button(action: onRemove) {
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

private struct LogMealForm: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: vm.editingMealID == nil ? "Log a meal" : "Edit meal", count: nil)
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
                    vm.saveMeal()
                } label: {
                    Text(vm.editingMealID == nil ? "Add to log" : "Save changes")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(vm.canAddCustomMeal ? Theme.accentText : Theme.textFaint)
                        .background(vm.canAddCustomMeal ? Theme.accent : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!vm.canAddCustomMeal)

                if vm.editingMealID != nil {
                    Button("Cancel") { vm.cancelEditingMeal() }
                        .font(.label(11))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.plain)
                }
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
