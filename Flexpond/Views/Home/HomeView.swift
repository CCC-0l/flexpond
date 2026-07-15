import SwiftUI
import FlexpondCore

struct HomeView: View {
    @ObservedObject var vm: AppViewModel

    private var dateLabel: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var isPlanEmpty: Bool {
        vm.todaysLiftingSchedule == nil && vm.todaysCardioSchedule == nil && vm.walkPlanItem == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateLabel.uppercased())
                    .font(.label(11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                Text("Ready to train.")
                    .font(.system(size: 24, weight: .heavy))
            }

            ReadinessTeaserCard(vm: vm)

            if isPlanEmpty {
                EmptyPlanCard(vm: vm)
            } else {
                TodayPlanSection(vm: vm)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickLinkCard(icon: .diet, title: "Diet") { vm.selectTab(.diet) }
                QuickLinkCard(icon: .physique, title: "Physique") { vm.selectTab(.physique) }
            }
        }
        .padding(.top, 6)
    }
}

private struct ReadinessTeaserCard: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        Button { vm.selectTab(.readiness) } label: {
            HStack(spacing: 15) {
                ZStack {
                    CircularRing(progress: Double(vm.homeReadinessScore) / 100, lineWidth: 6)
                    Text("\(vm.homeReadinessScore)")
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 3) {
                    Text("READINESS")
                        .font(.label(10))
                        .foregroundStyle(Theme.textTertiary)
                    Text(vm.homeReadinessLabel)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if vm.ouraConnected {
                        HStack(spacing: 5) {
                            Circle().fill(Theme.good).frame(width: 5, height: 5)
                            Text("LIVE · OURA")
                                .font(.label(9.5))
                                .foregroundStyle(Theme.good.opacity(0.85))
                        }
                        .padding(.top, 2)
                    }
                }
                Spacer()
                RowChevron()
            }
            .padding(16)
            .cardBackground()
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyPlanCard: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Add your first workout")
                .font(.system(size: 17, weight: .heavy))
            Text("Pick a training style, program, or a cardio goal. Everything you add shows up here as your to-do list.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
            PrimaryButton(title: "Choose a workout", systemImage: "plus", action: vm.goAddWorkout)
        }
        .padding(20)
        .background(Theme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1.5)
        )
    }
}

/// Today's full lifting + cardio schedule, visible the instant Home opens
/// — no tap required to see what's due. Walk (no day-by-day schedule)
/// shows as a compact row alongside the detailed cards.
private struct TodayPlanSection: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Today's plan", count: nil)

            if let lifting = vm.todaysLiftingSchedule {
                TodayScheduleCard(item: lifting, onOpen: vm.openLiftingToday) {
                    vm.removeFromPlan(lifting.id)
                }
            }
            if let cardio = vm.todaysCardioSchedule {
                TodayScheduleCard(item: cardio, onOpen: vm.openCardioToday) {
                    vm.removeFromPlan(cardio.id)
                }
            }
            if let walk = vm.walkPlanItem {
                WalkRow(goal: walk.goal, onOpen: vm.openWalk) {
                    vm.removeFromPlan(walk.id)
                }
            }

            DashedCTAButton(title: "Add workout", action: vm.goAddWorkout)
        }
    }
}

private struct TodayScheduleCard: View {
    var item: TodayScheduleItem
    var onOpen: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpen) {
                HStack(spacing: 13) {
                    IconBadge(text: item.badge, size: 40, cornerRadius: 11)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.category.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(item.variantName) · \(item.dayName)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    RowChevron()
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.sessionLabel)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                if !item.restLine.isEmpty {
                    Text(item.restLine)
                        .font(.label(11))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 2)
                }
            }

            if item.isRestDay {
                RestDayCard()
            } else {
                ExerciseList(items: item.exercises)
            }

            Button(action: onRemove) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                    Text("Remove")
                }
                .font(.label(11))
                .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(15)
        .cardBackground(radius: 20)
    }
}

private struct WalkRow: View {
    var goal: Int
    var onOpen: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onOpen) {
                HStack(spacing: 13) {
                    IconBadge(text: "WK", size: 40, cornerRadius: 11)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Walk")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(goal.formatted()) steps / day")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 8)
                    RowChevron()
                }
                .padding(13)
                .cardBackground(radius: 16)
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(width: 46, height: 46)
                    .cardBackground(radius: 16)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct QuickLinkCard: View {
    var icon: TabIconKind
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                TabIconShape(kind: icon, color: Theme.accent)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .cardBackground()
        }
        .buttonStyle(.plain)
    }
}
