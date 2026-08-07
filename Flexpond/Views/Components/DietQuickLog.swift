import SwiftUI
import FlexpondCore

/// Diet widgets shared between the Diet tab and Home's macro summary card
/// — same rendering and actions everywhere, matching the
/// `ExerciseScheduleList` precedent for sharing between Home and Workout.

struct MacroBars: View {
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

struct FoodLibraryRow: View {
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
                Text(vm.savedFoods.isEmpty ? "Log a custom meal on the Diet tab to start building your library." : "No foods match \"\(searchText)\".")
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
