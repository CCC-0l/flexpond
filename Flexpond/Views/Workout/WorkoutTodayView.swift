import SwiftUI
import FlexpondCore

/// Read-only "here's what's scheduled" view — the redesign dropped
/// per-exercise completion tracking entirely (no checkboxes, no "Complete
/// session", no progress bars).
struct WorkoutTodayView: View {
    @ObservedObject var vm: AppViewModel

    private var dayName: String {
        let name = WorkoutSchedule.weekdayNames[vm.effectiveWeekday]
        return vm.effectiveWeekday == vm.todayWeekday ? "\(name) · Today" : name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your program is on a fixed weekly schedule — here's what's due each day.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)

            DayStrip(vm: vm)

            VStack(alignment: .leading, spacing: 2) {
                Text([vm.selectedCategory?.displayName, vm.activeVariant?.name, "\(vm.frequency.rawValue)-day"].compactMap { $0 }.joined(separator: " · ").uppercased())
                    .font(.label(11))
                    .foregroundStyle(Theme.textTertiary)
                Text(vm.selectedTrainingDay?.label ?? "Rest / Active Recovery")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 4)
                Text(dayName)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                if !vm.isRestDay, !vm.restLine.isEmpty {
                    Text(vm.restLine)
                        .font(.label(11))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 2)
                }
            }

            if let day = vm.selectedTrainingDay {
                ExerciseList(items: day.items)
            } else {
                RestDayCard()
            }
        }
        .padding(.top, 6)
    }
}

private struct DayStrip: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        HStack(spacing: 7) {
            ForEach(vm.weekStrip) { day in
                Button { vm.selectWeekday(day.id) } label: {
                    VStack(spacing: 6) {
                        Text(day.abbreviation.prefix(1))
                            .font(.label(11, weight: .semibold))
                            .foregroundStyle(day.isSelected ? Theme.accentText : (day.isToday ? Theme.accent : Theme.textSecondary))
                        Circle()
                            .fill(day.isSelected ? Theme.accentText : (day.isRestDay ? Color.white.opacity(0.28) : Theme.accent))
                            .frame(width: 6, height: 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(day.isSelected ? Theme.accent : (day.isToday ? Theme.accent.opacity(0.13) : Color.white.opacity(0.05)))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

