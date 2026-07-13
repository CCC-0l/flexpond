import SwiftUI
import FlexpondCore

/// Custom bottom bar — the mockup builds its own rather than using system
/// tab chrome. Order is Workout, Diet, Home, Readiness, Physique with Home
/// centered (`dc.html` lines 653-672), which is *not* `AppTab`'s declaration
/// order, so it's spelled out explicitly here.
struct FlexpondTabBar: View {
    var selected: AppTab
    var onSelect: (AppTab) -> Void

    private let order: [(AppTab, TabIconKind)] = [
        (.workout, .workout),
        (.diet, .diet),
        (.home, .home),
        (.readiness, .readiness),
        (.physique, .physique),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(order, id: \.0) { tab, icon in
                let isSelected = tab == selected
                let color = isSelected ? Theme.accent : Theme.textSecondary
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 5) {
                        TabIconShape(kind: icon, color: color)
                            .frame(width: 23, height: 23)
                        Text(tab.label.uppercased())
                            .font(.label(9, weight: .medium))
                            .foregroundStyle(color)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 11)
        .padding(.bottom, 27)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}
