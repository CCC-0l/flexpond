import SwiftUI
import FlexpondCore

struct WorkoutDetailView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        Group {
            switch vm.selectedCategory {
            case .some(.program):
                ProgramDetailView(vm: vm)
            case .some(.walk):
                WalkDetailView(vm: vm)
            case .none:
                EmptyView()
            }
        }
        .padding(.top, 6)
    }
}

private struct ProgramDetailView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose your weekly training frequency, then pick a program built around it.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 10) {
                Text("TRAINING FREQUENCY")
                    .font(.label(11))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 2)

                HStack(spacing: 4) {
                    ForEach(TrainingFrequency.allCases, id: \.self) { freq in
                        let isSelected = vm.frequency == freq
                        Button {
                            vm.selectFrequency(freq)
                        } label: {
                            Text(freq.label)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isSelected ? Theme.accentText : Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(isSelected ? Theme.accent : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .cardBackground(radius: 13)
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Choose a program", count: vm.variantOptions.count)
                ForEach(vm.variantOptions) { option in
                    VariantCard(option: option) { vm.selectVariant(option.id) }
                }
            }

            PrimaryButton(title: "Start program", action: vm.startProgram)
        }
    }
}

private struct VariantCard: View {
    var option: VariantOption
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(option.variant.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(option.variant.description)
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(2)
                    }
                    Spacer(minLength: 8)
                    RadioDot(isSelected: option.isSelected)
                }
                FlowLayout(spacing: 7) {
                    ForEach(option.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.label(10.5))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                }
            }
            .padding(15)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(option.isSelected ? Theme.accent : Theme.hairline, lineWidth: option.isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RadioDot: View {
    var isSelected: Bool

    var body: some View {
        Circle()
            .stroke(isSelected ? Theme.accent : Color.white.opacity(0.25), lineWidth: 2)
            .frame(width: 22, height: 22)
            .overlay {
                if isSelected {
                    Circle().fill(Theme.accent).frame(width: 11, height: 11)
                }
            }
    }
}

private struct WalkDetailView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set your daily step goal. We'll track your progress toward it each day.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)

            VStack(spacing: 24) {
                VStack(spacing: 7) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(vm.walkGoal.formatted())
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundStyle(Theme.textPrimary)
                        Text("steps")
                            .font(.label(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text("DAILY GOAL")
                        .font(.label(11))
                        .foregroundStyle(Theme.textTertiary)
                }

                VStack(spacing: 9) {
                    Slider(
                        value: Binding(
                            get: { Double(vm.walkGoal) },
                            set: { vm.setWalkGoal(Int($0)) }
                        ),
                        in: 5000...20000,
                        step: 500
                    )
                    .tint(Theme.accent)
                    HStack {
                        Text("5,000")
                        Spacer()
                        Text("20,000")
                    }
                    .font(.label(11))
                    .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 26)
            .cardBackground(radius: 20)

            PrimaryButton(
                title: vm.walkGoalSaved ? "Goal set" : "Set goal",
                systemImage: vm.walkGoalSaved ? "checkmark" : nil,
                action: vm.saveWalkGoal
            )
        }
    }
}
