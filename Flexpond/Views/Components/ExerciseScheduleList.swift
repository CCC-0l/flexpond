import SwiftUI
import FlexpondCore

/// Shared exercise list + rest-day card, used by both the Workout tab's
/// Today screen and Home's today-schedule cards so both render a day's
/// exercises identically. Read-only by default (`completedIDs == nil`);
/// passing `completedIDs`/`onToggle` turns it into a same-day checklist
/// with a progress header and per-row checkboxes — used only where a real
/// "today" is being shown, since there's no concept of completing a
/// past/future day.
struct ExerciseList: View {
    var items: [ExerciseEntry]
    var completedIDs: Set<String>? = nil
    var onToggle: ((ExerciseEntry) -> Void)? = nil
    var onToggleAll: (() -> Void)? = nil

    private var completedCount: Int {
        guard let completedIDs else { return 0 }
        return items.filter { completedIDs.contains($0.id) }.count
    }

    private var isFullyComplete: Bool { !items.isEmpty && completedCount == items.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if completedIDs != nil, !items.isEmpty {
                progressHeader
            }
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ExerciseRow(
                        item: item,
                        isLast: index == items.count - 1,
                        isComplete: completedIDs?.contains(item.id) ?? false,
                        isInteractive: completedIDs != nil,
                        onToggle: { onToggle?(item) }
                    )
                }
            }
            .cardBackground(radius: 18)
        }
    }

    private var progressHeader: some View {
        HStack(spacing: 10) {
            Text("\(completedCount) of \(items.count) done")
                .font(.label(11))
                .foregroundStyle(Theme.textTertiary)
            GeometryReader { geo in
                Capsule().fill(Color.white.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(Theme.good).frame(width: geo.size.width * (items.isEmpty ? 0 : Double(completedCount) / Double(items.count)))
                    }
            }
            .frame(height: 6)
            Button { onToggleAll?() } label: {
                Text(isFullyComplete ? "Completed" : "Mark complete")
                    .font(.label(10.5, weight: .bold))
                    .foregroundStyle(isFullyComplete ? Theme.good : Theme.accent)
                    .fixedSize()
            }
            .buttonStyle(.plain)
        }
    }
}

struct ExerciseRow: View {
    var item: ExerciseEntry
    var isLast: Bool
    var isComplete: Bool = false
    var isInteractive: Bool = false
    var onToggle: (() -> Void)? = nil

    var body: some View {
        Group {
            if isInteractive {
                Button(action: { onToggle?() }) { rowContent }
                    .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 15)
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 13) {
            if isInteractive {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isComplete ? Theme.good : Theme.textTertiary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isComplete ? Theme.textTertiary : Theme.textPrimary)
                    .strikethrough(isComplete, color: Theme.textTertiary)
                if !item.setsReps.isEmpty {
                    Text(item.setsReps)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xEAF3FF))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.accent.opacity(isComplete ? 0.06 : 0.16))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Theme.accent.opacity(isComplete ? 0.12 : 0.3), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .opacity(isComplete ? 0.6 : 1)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
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
