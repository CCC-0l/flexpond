import SwiftUI
import FlexpondCore

struct WorkoutTodayView: View {
    @ObservedObject var vm: AppViewModel

    private var weekScheduled: Int { vm.weekStrip.filter { !$0.isRestDay }.count }
    private var weekDone: Int { vm.weekStrip.filter { !$0.isRestDay && $0.isDone }.count }

    private var dayName: String {
        let name = WorkoutSchedule.weekdayNames[vm.effectiveWeekday]
        return vm.effectiveWeekday == vm.todayWeekday ? "\(name) · Today" : name
    }

    private var restRangeLabel: String {
        if case .lift(let category) = vm.selectedCategory { return category.restRange }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            WeekSummaryCard(scheduled: weekScheduled, done: weekDone)

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
                if !restRangeLabel.isEmpty {
                    Text("Rest \(restRangeLabel) between sets")
                        .font(.label(11))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 2)
                }
            }

            if let day = vm.selectedTrainingDay {
                SessionChecklist(vm: vm, day: day)
            } else {
                RestDayCard()
            }
        }
        .padding(.top, 6)
    }
}

private struct WeekSummaryCard: View {
    var scheduled: Int
    var done: Int

    private var progress: Double { scheduled == 0 ? 0 : Double(done) / Double(scheduled) }

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Text("THIS WEEK")
                    .font(.label(10))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(done)/\(scheduled)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xEAF3FF))
            }
            GeometryReader { geo in
                Capsule().fill(Color.white.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(Theme.accent).frame(width: geo.size.width * progress)
                    }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .cardBackground(radius: 14)
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
                        if day.isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(day.isSelected ? Theme.accentText : Theme.good)
                        } else if !day.isRestDay {
                            Circle()
                                .fill(day.isSelected ? Theme.accentText : Theme.accent)
                                .frame(width: 6, height: 6)
                        } else {
                            Circle().fill(Color.clear).frame(width: 6, height: 6)
                        }
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

private struct SessionChecklist: View {
    @ObservedObject var vm: AppViewModel
    var day: TrainingDay

    private var doneCount: Int { vm.todayCompletedIndices.count }
    private var progress: Double { day.items.isEmpty ? 0 : Double(doneCount) / Double(day.items.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                GeometryReader { geo in
                    Capsule().fill(Color.white.opacity(0.07))
                        .overlay(alignment: .leading) {
                            Capsule().fill(Theme.accent).frame(width: geo.size.width * progress)
                        }
                }
                .frame(height: 7)
                Text("\(doneCount)/\(day.items.count)")
                    .font(.label(11))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize()
            }

            VStack(spacing: 0) {
                ForEach(Array(day.items.enumerated()), id: \.offset) { index, item in
                    ExerciseRow(
                        item: item,
                        isDone: vm.todayCompletedIndices.contains(index),
                        isLast: index == day.items.count - 1
                    ) {
                        vm.toggleExercise(index)
                    }
                }
            }
            .cardBackground(radius: 18)

            if vm.isSessionComplete {
                CompletedBadge()
            } else {
                PrimaryButton(title: "Complete session", action: vm.completeSession)
            }
        }
    }
}

private struct ExerciseRow: View {
    var item: ExerciseEntry
    var isDone: Bool
    var isLast: Bool
    var toggle: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Button(action: toggle) {
                Circle()
                    .strokeBorder(isDone ? Theme.good : Color.white.opacity(0.2), lineWidth: 2)
                    .background(Circle().fill(isDone ? Theme.good.opacity(0.15) : Color.clear))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.good)
                        }
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isDone ? Theme.textTertiary : Theme.textPrimary)
                    .strikethrough(isDone, color: Theme.textTertiary)
                if !item.setsReps.isEmpty {
                    Text(item.setsReps)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xEAF3FF))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.accent.opacity(0.16))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Theme.accent.opacity(0.3), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 15 + 24 + 13)
            }
        }
    }
}

private struct CompletedBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
            Text("Session completed")
                .font(.system(size: 15, weight: .heavy))
        }
        .foregroundStyle(Theme.good)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.good.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.good.opacity(0.3), lineWidth: 1))
    }
}

private struct RestDayCard: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Recovery day")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("No lifting scheduled today. Go for a walk, stretch, or do some light mobility work.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
        .cardBackground(radius: 18)
    }
}
