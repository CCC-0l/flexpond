import SwiftUI

/// The app's own in-content header (`dc.html` lines 44-59) — not a system
/// nav bar. Either a "FLEXPÖND" wordmark eyebrow or a back button on the
/// left, a circular avatar on the right, and a large bold title below.
/// (The mockup's header sits under a simulated status bar, hence its 52pt
/// top padding — real iOS gives us the safe area for free, so this doesn't
/// need that offset.)
struct FlexpondHeader: View {
    var title: String
    var showBack: Bool = false
    var backLabel: String = ""
    var onBack: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if showBack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                            Text(backLabel.uppercased())
                                .font(.label(11))
                        }
                        .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("FLEXPÖND")
                        .font(.label(11, weight: .semibold))
                        .tracking(2.5)
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                AvatarBadge()
            }
            Text(title)
                .font(.system(size: 33, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

private struct AvatarBadge: View {
    var body: some View {
        Circle()
            .fill(Theme.card)
            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            .overlay(
                Text("A")
                    .font(.label(13))
                    .foregroundStyle(Theme.textSecondary)
            )
            .frame(width: 34, height: 34)
    }
}
