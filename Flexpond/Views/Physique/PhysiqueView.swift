import SwiftUI
import FlexpondCore

struct PhysiqueView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SegmentedControl(vm: vm)

            switch vm.physiqueViewMode {
            case .timeline: TimelineSection(vm: vm)
            case .compare: CompareSection(vm: vm)
            }
        }
        .padding(.top, 6)
    }
}

private struct SegmentedControl: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        HStack(spacing: 4) {
            segment("Timeline", isSelected: vm.physiqueViewMode == .timeline) { vm.setPhysiqueViewMode(.timeline) }
            segment("Compare", isSelected: vm.physiqueViewMode == .compare) { vm.setPhysiqueViewMode(.compare) }
        }
        .padding(4)
        .cardBackground(radius: 13)
    }

    private func segment(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? Theme.accentText : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct TimelineSection: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 14) {
            ForEach(vm.physiqueEntries) { entry in
                EntryPoseGrid(entry: entry, vm: vm)
            }
            LogEntryForm(vm: vm)
        }
    }
}

private struct EntryPoseGrid: View {
    var entry: PhysiqueEntry
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.label(11))
                        .foregroundStyle(Theme.accent)
                }
                Spacer()
                Button { vm.deletePhysiqueEntry(entry.id) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            EntryStatsRow(entry: entry, vm: vm)

            HStack(spacing: 8) {
                ForEach(PhysiquePose.allCases) { pose in
                    PosePhoto(label: pose.label, fileName: entry.photoFileName(for: pose))
                }
            }
        }
        .padding(15)
        .cardBackground(radius: 18)
    }
}

/// Weight + BMI for one entry, with deltas vs. the chronologically
/// previous entry. Tapping the weight opens an inline editor — self
/// -reported stats mean typos/forgotten entries are the common case.
private struct EntryStatsRow: View {
    var entry: PhysiqueEntry
    @ObservedObject var vm: AppViewModel
    @State private var isEditingWeight = false
    @State private var weightDraft = ""

    var body: some View {
        HStack(spacing: 10) {
            Button {
                weightDraft = entry.weightPounds.map(String.init) ?? ""
                isEditingWeight = true
            } label: {
                HStack(spacing: 6) {
                    if let weight = entry.weightPounds {
                        Text("\(weight) lb")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    } else {
                        Text("Log weight")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    if let delta = vm.weightDelta(for: entry) {
                        StatDeltaBadge(value: Double(delta), suffix: "lb")
                    }
                }
            }
            .buttonStyle(.plain)

            if let bmi = vm.bmi(for: entry) {
                Divider().frame(height: 14)
                HStack(spacing: 6) {
                    Text("BMI \(bmi, specifier: "%.1f")")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                    if let bmiDelta = vm.bmiDelta(for: entry) {
                        StatDeltaBadge(value: bmiDelta, suffix: "", decimals: 1)
                    }
                }
            }
            Spacer()
        }
        .alert("Edit weight", isPresented: $isEditingWeight) {
            TextField("Weight (lb)", text: $weightDraft)
                .keyboardType(.numberPad)
            Button("Save") { vm.updateEntryWeight(entry.id, weightPounds: Int(weightDraft)) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct LogEntryForm: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        HStack(spacing: 10) {
            TextField("Weight (lb)", text: $vm.newEntryWeight)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
                .padding(.vertical, 13)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Theme.hairline, lineWidth: 1))

            Button {
                vm.addPhysiqueEntry()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Log entry")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(Theme.accent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

/// Renders the bundled sample photo when available, otherwise the same
/// placeholder tile used for user-added entries with no photo yet.
private struct PosePhoto: View {
    var label: String
    var fileName: String?

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let fileName, let uiImage = PhysiquePhotoCache.image(named: fileName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Theme.background)
                        .overlay(Image(systemName: "photo").foregroundStyle(Theme.textFaint))
                }
            }
            .aspectRatio(170.0 / 451.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(label.uppercased())
                .font(.label(10))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CompareSection: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tap any two entries to compare them side by side.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)

            ForEach(vm.compareOptions) { option in
                Button { vm.toggleCompareEntry(option.id) } label: {
                    HStack(spacing: 13) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.label)
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(option.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.label(11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        if let number = option.badgeNumber {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("\(number)")
                                        .font(.label(12))
                                        .foregroundStyle(Theme.accentText)
                                )
                        } else {
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(option.isSelected ? Theme.accent.opacity(0.08) : Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(option.isSelected ? Theme.accent : Theme.hairline, lineWidth: option.isSelected ? 1.5 : 1))
                }
                .buttonStyle(.plain)
            }

            if let entryA = vm.compareEntryA, let entryB = vm.compareEntryB {
                HStack {
                    entryHeader(entryA)
                    Spacer()
                    entryHeader(entryB)
                }
                .padding(.top, 8)

                CompareStatsRow(entryA: entryA, entryB: entryB, vm: vm)

                ForEach(PhysiquePose.allCases) { pose in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(pose.label.uppercased())
                            .font(.label(10))
                            .foregroundStyle(Theme.textTertiary)
                        HStack(spacing: 10) {
                            PosePhoto(label: pose.label, fileName: entryA.photoFileName(for: pose))
                            PosePhoto(label: pose.label, fileName: entryB.photoFileName(for: pose))
                        }
                    }
                }
            } else {
                Text("Select two entries above to see them side by side.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .cardBackground(radius: 16)
            }
        }
    }

    private func entryHeader(_ entry: PhysiqueEntry) -> some View {
        VStack(spacing: 2) {
            Text(entry.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                .font(.label(10.5))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Weight/BMI for the two entries selected in Compare, with the delta
/// between them (A → B), distinct from Timeline's "vs. previous entry"
/// delta.
private struct CompareStatsRow: View {
    var entryA: PhysiqueEntry
    var entryB: PhysiqueEntry
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                statColumn(weight: entryA.weightPounds, bmi: vm.bmi(for: entryA))
                Spacer()
                statColumn(weight: entryB.weightPounds, bmi: vm.bmi(for: entryB))
            }
            if let weightA = entryA.weightPounds, let weightB = entryB.weightPounds {
                HStack(spacing: 10) {
                    StatDeltaBadge(value: Double(weightB - weightA), suffix: "lb")
                    if let bmiA = vm.bmi(for: entryA), let bmiB = vm.bmi(for: entryB) {
                        StatDeltaBadge(value: bmiB - bmiA, suffix: "BMI", decimals: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(13)
        .cardBackground(radius: 14)
    }

    private func statColumn(weight: Int?, bmi: Double?) -> some View {
        VStack(spacing: 2) {
            Text(weight.map { "\($0) lb" } ?? "—")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            if let bmi {
                Text("BMI \(bmi, specifier: "%.1f")")
                    .font(.label(10.5))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
