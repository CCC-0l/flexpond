import SwiftUI
import FlexpondCore

struct DietTrendsView: View {
    @ObservedObject var vm: AppViewModel
    private let days = 14

    private var history: [DailyMacroSummary] { vm.mealHistory(days: days) }
    private var averages: MealHistoryAverages { vm.mealHistoryAverages(days: days) }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Calories · last \(days) days", count: nil)
                Sparkline(series: history.map { Double($0.calories) }, color: Theme.accent, lineWidth: 2)
                    .frame(height: 90)
                    .padding(14)
                    .cardBackground(radius: 16)
                if let first = history.first?.date, let last = history.last?.date {
                    HStack {
                        Text(first.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text(last.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(.label(10.5))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 4)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Averages", count: nil)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    statTile(title: "Avg Calories", value: "\(averages.averageCalories)", unit: "cal")
                    statTile(title: "Days Logged", value: "\(averages.daysLogged)", unit: "of \(days)")
                    statTile(title: "Avg Protein", value: "\(averages.averageProteinGrams)", unit: "g")
                    statTile(title: "Avg Carbs", value: "\(averages.averageCarbGrams)", unit: "g")
                    statTile(title: "Avg Fat", value: "\(averages.averageFatGrams)", unit: "g")
                }
            }
        }
    }

    private func statTile(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.label(10))
                .foregroundStyle(Theme.textTertiary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .cardBackground(radius: 14)
    }
}
