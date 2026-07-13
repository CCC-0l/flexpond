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
                EntryPoseGrid(entry: entry)
            }
            DashedCTAButton(title: "Add today's photos", action: vm.addPhysiqueEntry)
        }
    }
}

private struct EntryPoseGrid: View {
    var entry: PhysiqueEntry

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
                Text("UP TO 3 PHOTOS")
                    .font(.label(10))
                    .foregroundStyle(Theme.textTertiary)
            }
            HStack(spacing: 8) {
                ForEach(PhysiquePose.allCases) { pose in
                    PosePlaceholder(label: pose.label)
                }
            }
        }
        .padding(15)
        .cardBackground(radius: 18)
    }
}

private struct PosePlaceholder: View {
    var label: String

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.background)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(Theme.textFaint)
                )
            Text(label.uppercased())
                .font(.label(10))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CompareSection: View {
    @ObservedObject var vm: AppViewModel

    private var entries: [PhysiqueEntry] { vm.physiqueEntries }
    private var indexA: Int { min(vm.compareIndexA, max(entries.count - 1, 0)) }
    private var indexB: Int { min(vm.compareIndexB, max(entries.count - 1, 0)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BEFORE")
                .font(.label(11))
                .foregroundStyle(Theme.textTertiary)
            EntryPicker(entries: entries, selectedIndex: indexA) { vm.selectCompareA($0) }

            Text("AFTER")
                .font(.label(11))
                .foregroundStyle(Theme.textTertiary)
            EntryPicker(entries: entries, selectedIndex: indexB) { vm.selectCompareB($0) }

            if entries.indices.contains(indexA), entries.indices.contains(indexB) {
                let entryA = entries[indexA]
                let entryB = entries[indexB]

                HStack {
                    entryHeader(entryA)
                    Spacer()
                    entryHeader(entryB)
                }

                ForEach(PhysiquePose.allCases) { pose in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(pose.label.uppercased())
                            .font(.label(10))
                            .foregroundStyle(Theme.textTertiary)
                        HStack(spacing: 10) {
                            PosePlaceholder(label: pose.label)
                            PosePlaceholder(label: pose.label)
                        }
                    }
                }
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

private struct EntryPicker: View {
    var entries: [PhysiqueEntry]
    var selectedIndex: Int
    var onSelect: (Int) -> Void

    var body: some View {
        FlowLayout(spacing: 7) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                let isSelected = index == selectedIndex
                Button { onSelect(index) } label: {
                    Text(entry.label)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(isSelected ? Color(hex: 0xEAF3FF) : Theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(isSelected ? Theme.accent.opacity(0.16) : Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
