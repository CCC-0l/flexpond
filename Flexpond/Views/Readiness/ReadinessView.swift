import SwiftUI
import FlexpondCore

struct ReadinessView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        if let readiness = vm.readiness {
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
            .padding(.top, 6)
        } else {
            ProgressView()
                .tint(Theme.accent)
                .frame(maxWidth: .infinity, minHeight: 300)
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
