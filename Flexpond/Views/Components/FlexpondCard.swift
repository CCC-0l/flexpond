import SwiftUI

/// Tappable icon + title + subtitle row used for browse categories and plan
/// entries — the `#17171A` rounded card that repeats throughout the mockup.
struct FlexpondCard: View {
    var badge: String
    var badgeBackground: Color = Theme.accent.opacity(0.14)
    var badgeForeground: Color = Theme.accent
    var title: String
    var subtitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconBadge(text: badge, background: badgeBackground, foreground: badgeForeground)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 8)
                RowChevron()
            }
            .padding(14)
            .cardBackground()
        }
        .buttonStyle(.plain)
    }
}
