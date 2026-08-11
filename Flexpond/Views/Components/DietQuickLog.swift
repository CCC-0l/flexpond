import SwiftUI
import FlexpondCore

/// Diet widgets shared between the Diet tab and Home's macro summary card
/// — same rendering and actions everywhere, matching the
/// `ExerciseScheduleList` precedent for sharing between Home and Workout.

/// One compact card holding all 3 macro rows — previously 3 separate
/// bordered cards, which read as 3 distinct items instead of one
/// glanceable summary.
struct MacroBars: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 15) {
            macroRow(title: "Protein", consumed: vm.dietSummary.proteinConsumed, target: vm.dietSummary.proteinTarget, progress: vm.dietSummary.proteinProgress, color: Theme.accent)
            macroRow(title: "Carbs", consumed: vm.dietSummary.carbConsumed, target: vm.dietSummary.carbTarget, progress: vm.dietSummary.carbProgress, color: Theme.good)
            macroRow(title: "Fat", consumed: vm.dietSummary.fatConsumed, target: vm.dietSummary.fatTarget, progress: vm.dietSummary.fatProgress, color: Theme.warning)
        }
        .padding(14)
        .cardBackground(radius: 16)
    }

    private func macroRow(title: String, consumed: Int, target: Int, progress: Double, color: Color) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(consumed)g / \(target)g")
                    .font(.label(11))
                    .foregroundStyle(Theme.textSecondary)
            }
            GeometryReader { geo in
                Capsule().fill(Color.white.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color).frame(width: geo.size.width * progress)
                    }
            }
            .frame(height: 6)
        }
    }
}

struct FoodLibraryRow: View {
    @ObservedObject var vm: AppViewModel
    @State private var editingFood: SavedFood?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Your food library", count: nil)

            if vm.savedFoods.isEmpty {
                Text("Log a custom meal below to start building your library.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.savedFoods) { food in
                            FoodLibraryCard(food: food, onLog: { vm.logSavedFood(food) }, onEdit: { editingFood = food }, onDelete: { vm.deleteSavedFood(food.id) })
                        }
                    }
                    .padding(.top, 6) // room for the edit/delete badges to overflow the card
                }
            }
        }
        .sheet(item: $editingFood) { food in
            EditSavedFoodSheet(food: food, vm: vm)
        }
    }
}

private struct FoodLibraryCard: View {
    var food: SavedFood
    var onLog: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    @State private var showDeleteConfirm = false

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
        .overlay(alignment: .topLeading) {
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textTertiary)
                    .background(Circle().fill(Theme.background))
            }
            .buttonStyle(.plain)
            .offset(x: -6, y: -6)
        }
        .overlay(alignment: .topTrailing) {
            Button { showDeleteConfirm = true } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textTertiary)
                    .background(Circle().fill(Theme.background))
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
        .confirmationDialog("Remove \"\(food.name)\" from your food library?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct EditSavedFoodSheet: View {
    let food: SavedFood
    @ObservedObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carb: String
    @State private var fat: String

    init(food: SavedFood, vm: AppViewModel) {
        self.food = food
        self.vm = vm
        _name = State(initialValue: food.name)
        _calories = State(initialValue: String(food.calories))
        _protein = State(initialValue: String(food.proteinGrams))
        _carb = State(initialValue: String(food.carbGrams))
        _fat = State(initialValue: String(food.fatGrams))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (Int(calories) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Food name", text: $name)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(11)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.hairline, lineWidth: 1))

                HStack(spacing: 8) {
                    macroInput("Cal", text: $calories)
                    macroInput("P (g)", text: $protein)
                    macroInput("C (g)", text: $carb)
                    macroInput("F (g)", text: $fat)
                }

                Spacer()
            }
            .padding(20)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.updateSavedFood(
                            food.id,
                            name: name.trimmingCharacters(in: .whitespaces),
                            calories: Int(calories) ?? 0,
                            proteinGrams: Int(protein) ?? 0,
                            carbGrams: Int(carb) ?? 0,
                            fatGrams: Int(fat) ?? 0
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? Theme.accent : Theme.textFaint)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func macroInput(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 13))
            .foregroundStyle(Theme.textPrimary)
            .padding(.vertical, 10)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
    }
}

/// Today's meals as a single chronological list, timestamped by when each
/// was logged — no fixed Breakfast/Lunch/Dinner/Snack buckets, since a
/// 6-small-meals split (common for bodybuilders) doesn't map cleanly onto
/// 4 slots. Tapping a row opens it for editing.
struct MealTimeline: View {
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
    @State private var showRemoveConfirm = false

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
            Button { showRemoveConfirm = true } label: {
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
        .confirmationDialog("Remove \"\(meal.name)\" from today's log?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive, action: onRemove)
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct LogMealForm: View {
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

                if vm.editingMealID == nil {
                    Toggle(isOn: $vm.saveToLibrary) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save to food library")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("For meals you'll eat again — leave off for one-offs like eating out.")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .tint(Theme.accent)
                    .padding(.vertical, 2)
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
