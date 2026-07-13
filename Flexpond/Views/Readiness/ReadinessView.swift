import SwiftUI
import FlexpondCore

/// Three mutually-exclusive states, matching the mockup's Oura integration
/// doc block: a persistent connect/sync status bar (hidden only while the
/// connect form is open), the connect form itself, and either the static
/// pre-connect mock content or the live Oura-driven content.
struct ReadinessView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !vm.ouraConnectOpen {
                OuraStatusBar(vm: vm)
            }

            if vm.ouraConnectOpen {
                OuraConnectForm(vm: vm)
            } else if vm.ouraConnected {
                OuraConnectedContent(vm: vm)
            } else if let readiness = vm.readiness {
                MockReadinessContent(readiness: readiness)
            }
        }
        .padding(.top, 6)
    }
}

// MARK: - Status bar

private struct OuraStatusBar: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        if vm.ouraConnected {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Circle().fill(Theme.good).frame(width: 7, height: 7)
                    Text("\(vm.ouraSummaryLine) · real Oura data")
                        .font(.label(11.5))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button("Sync") { vm.openOuraConnect() }
                    .font(.label(11))
                    .foregroundStyle(Theme.accent)
                Button("Disconnect") { vm.disconnectOura() }
                    .font(.label(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.good.opacity(0.25), lineWidth: 1))
        } else {
            Button {
                vm.openOuraConnect()
            } label: {
                Text("Connect your Oura Ring")
                    .font(.system(size: 13.5, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(Theme.accent)
                    .background(Theme.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Theme.accent.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Connect form

private struct OuraConnectForm: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connect Oura Ring")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)

            Text("Generate a free Personal Access Token at ")
                .foregroundColor(Theme.textSecondary)
            + Text("cloud.ouraring.com/personal-access-tokens")
                .foregroundColor(Theme.accent)
            + Text(" — no developer approval needed for your own data. Paste it below and tap Fetch.")
                .foregroundColor(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("PERSONAL ACCESS TOKEN")
                    .font(.label(10))
                    .foregroundStyle(Theme.textTertiary)
                TextField("Paste your Oura token", text: $vm.ouraToken)
                    .font(.system(size: 13, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(13)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
            }

            PrimaryButton(title: vm.ouraSyncing ? "Fetching…" : "Fetch my Readiness data") {
                Task { await vm.connectOura() }
            }
            .disabled(vm.ouraSyncing)

            if let error = vm.ouraSyncError {
                Text(error)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.warning)
                    .padding(12)
                    .background(Theme.warning.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.warning.opacity(0.3), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            GhostTextButton(title: "Cancel") { vm.closeOuraConnect() }
        }
        .font(.system(size: 13))
        .lineSpacing(3)
    }
}

// MARK: - Connected content

private struct OuraConnectedContent: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(spacing: 5) {
                ZStack {
                    CircularRing(progress: Double(vm.ouraScore ?? 0) / 100, lineWidth: 12)
                    VStack(spacing: 5) {
                        Text("\(vm.ouraScore ?? 0)")
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundStyle(Theme.textPrimary)
                        Text("OUT OF 100")
                            .font(.label(9.5))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .frame(width: 158, height: 158)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Focus today", count: vm.ouraFocusItems.count)
                ForEach(vm.ouraFocusItems) { item in
                    OuraFocusCard(item: item)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Contributors", count: vm.ouraGridItems.count)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(vm.ouraGridItems) { item in
                        OuraGridCard(item: item)
                    }
                }
            }

            Text("Live data synced from your Oura Ring — \(vm.ouraDay ?? "").")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.accent.opacity(0.2), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct OuraFocusCard: View {
    var item: OuraMetricItem

    private var tint: Color {
        switch item.status {
        case .optimal: return Theme.good
        case .balanced: return Theme.accent
        case .payAttention: return Theme.warning
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(item.status.rawValue)
                    .font(.label(10))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tint.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            HStack(spacing: 10) {
                GeometryReader { geo in
                    Capsule().fill(Color.white.opacity(0.07))
                        .overlay(alignment: .leading) {
                            Capsule().fill(tint).frame(width: geo.size.width * Double(item.score) / 100)
                        }
                }
                .frame(height: 8)
                Text("\(item.score)/100")
                    .font(.label(12))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize()
            }
            Text("Real Oura contributor score — lowest of your eight today.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardBackground(radius: 16)
    }
}

private struct OuraGridCard: View {
    var item: OuraMetricItem

    private var tint: Color {
        switch item.status {
        case .optimal: return Theme.good
        case .balanced: return Theme.accent
        case .payAttention: return Theme.warning
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(item.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Circle().fill(tint).frame(width: 7, height: 7)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(item.score)")
                    .font(.system(size: 23, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text("/100")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(item.status.rawValue)
                .font(.label(10.5))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .cardBackground(radius: 16)
    }
}

// MARK: - Mock (pre-connect) content — unchanged static copy from the design

private struct MockReadinessContent: View {
    var readiness: ReadinessData

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 15) {
                ZStack {
                    CircularRing(progress: Double(readiness.score) / 100, lineWidth: 12)
                    VStack(spacing: 5) {
                        Text("\(readiness.score)")
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundStyle(Theme.textPrimary)
                        Text("OUT OF 100")
                            .font(.label(9.5))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .frame(width: 158, height: 158)

                VStack(spacing: 5) {
                    Text(readiness.headline)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text(readiness.summary)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 270)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Focus today", count: readiness.focusAreas.count)
                ForEach(readiness.focusAreas) { area in
                    FocusAreaCard(area: area)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Contributors", count: readiness.contributors.count)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(readiness.contributors) { contributor in
                        ContributorCard(contributor: contributor)
                    }
                }
            }
        }
    }
}

private struct FocusAreaCard: View {
    var area: ReadinessFocusArea

    private var tint: Color { area.severity == .attention ? Theme.warning : Theme.good }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(area.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(area.severity == .attention ? "Pay attention" : "Good")
                    .font(.label(10))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tint.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            Text(area.detail)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
            TrendBars(values: area.trend, color: tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(tint.opacity(0.28), lineWidth: 1))
    }
}

private struct ContributorCard: View {
    var contributor: ReadinessContributor

    private var tint: Color { contributor.isPositive ? Theme.good : Theme.warning }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(contributor.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Circle().fill(tint).frame(width: 7, height: 7)
            }
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(contributor.value)
                    .font(.system(size: 23, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(contributor.unit)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(contributor.delta)
                    .font(.label(11))
                    .foregroundStyle(tint)
            }
            Sparkline(series: contributor.series, color: tint)
                .frame(height: 24)
            Text(contributor.footnote)
                .font(.label(10.5))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .cardBackground(radius: 16)
    }
}
