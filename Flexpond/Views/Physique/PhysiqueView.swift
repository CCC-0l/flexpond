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
                    PosePhoto(label: pose.label, fileName: entry.photoFileName(for: pose))
                }
            }
        }
        .padding(15)
        .cardBackground(radius: 18)
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
