import SwiftUI
import FlexpondCore

struct DietSetupView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tell us about yourself to calculate your daily calorie and macro targets.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)

            GenderPicker(vm: vm)

            HStack(spacing: 10) {
                NumberField(label: "Age", value: $vm.dietProfile.age)
                HeightField(vm: vm)
                NumberField(label: "Weight (lb)", value: $vm.dietProfile.weightPounds)
            }

            VStack(alignment: .leading, spacing: 9) {
                Text("ACTIVITY LEVEL")
                    .font(.label(11))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 2)
                ForEach(ActivityLevel.allCases) { level in
                    RadioRow(
                        title: level.label,
                        detail: level.detail,
                        isSelected: vm.dietProfile.activity == level
                    ) { vm.dietProfile.activity = level }
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                Text("YOUR GOAL")
                    .font(.label(11))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 2)
                ForEach(DietGoal.allCases) { goal in
                    RadioRow(
                        title: goal.label,
                        detail: goal.detail,
                        isSelected: vm.dietProfile.goal == goal
                    ) { vm.dietProfile.goal = goal }
                }
            }

            AdvancedSettings(vm: vm)

            PrimaryButton(title: "Calculate my macros", action: vm.calculateDiet)
        }
        .padding(.top, 6)
    }
}

private struct GenderPicker: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("GENDER")
                .font(.label(11))
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 2)
            HStack(spacing: 4) {
                segment("Male", .male)
                segment("Female", .female)
            }
            .padding(4)
            .cardBackground(radius: 13)
        }
    }

    private func segment(_ title: String, _ gender: DietGender) -> some View {
        let isSelected = vm.dietProfile.gender == gender
        return Button {
            vm.dietProfile.gender = gender
        } label: {
            Text(title)
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

private struct NumberField: View {
    var label: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.label(10))
                .foregroundStyle(Theme.textTertiary)
            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.vertical, 12)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HeightField: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HEIGHT")
                .font(.label(10))
                .foregroundStyle(Theme.textTertiary)
            HStack(spacing: 5) {
                heightInput(placeholder: "ft", value: $vm.dietProfile.heightFeet)
                heightInput(placeholder: "in", value: $vm.dietProfile.heightInches)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func heightInput(placeholder: String, value: Binding<Int>) -> some View {
        TextField(placeholder, value: value, format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.vertical, 12)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
    }
}

private struct RadioRow: View {
    var title: String
    var detail: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(detail)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Circle()
                    .stroke(isSelected ? Theme.accent : Color.white.opacity(0.25), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if isSelected {
                            Circle().fill(Theme.accent).frame(width: 10, height: 10)
                        }
                    }
            }
            .padding(13)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }
}

private struct AdvancedSettings: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                vm.toggleDietAdvanced()
            } label: {
                HStack {
                    Text("ADVANCED SETTINGS")
                    Spacer()
                    Text(vm.dietAdvancedOpen ? "−" : "+")
                        .font(.system(size: 16))
                }
                .font(.label(11))
                .foregroundStyle(Theme.accent)
                .padding(.top, 16)
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
            }
            .buttonStyle(.plain)

            if vm.dietAdvancedOpen {
                VStack(alignment: .leading, spacing: 9) {
                    Text("BMR FORMULA")
                        .font(.label(10))
                        .foregroundStyle(Theme.textTertiary)
                    HStack(spacing: 4) {
                        formulaSegment("Mifflin-St Jeor", .mifflin)
                        formulaSegment("Katch-McArdle", .katch)
                    }
                    .padding(4)
                    .cardBackground(radius: 13)

                    if vm.dietProfile.formula == .katch {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BODY FAT %")
                                .font(.label(10))
                                .foregroundStyle(Theme.textTertiary)
                            TextField("", value: $vm.dietProfile.bodyFatPercent, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.vertical, 12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    private func formulaSegment(_ title: String, _ formula: BMRFormula) -> some View {
        let isSelected = vm.dietProfile.formula == formula
        return Button {
            vm.dietProfile.formula = formula
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.accentText : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
