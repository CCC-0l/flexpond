import SwiftUI
import FlexpondCore

/// Shared read-only exercise list + rest-day card, used by both the
/// Workout tab's Today screen and Home's today-schedule cards so both
/// render a day's exercises identically.
struct ExerciseList: View {
    var items: [ExerciseEntry]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ExerciseRow(item: item, isLast: index == items.count - 1)
            }
        }
        .cardBackground(radius: 18)
    }
}

struct ExerciseRow: View {
    var item: ExerciseEntry
    var isLast: Bool

    var body: some View {
        HStack(spacing: 13) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
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
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 15)
            }
        }
    }
}

struct RestDayCard: View {
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
