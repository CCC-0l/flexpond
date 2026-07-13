import SwiftUI

/// Uppercase mono eyebrow label with a right-aligned zero-padded count, e.g. "LIFTING · 03".
struct SectionHeader: View {
    var title: String
    var count: Int?

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title.uppercased())
                .font(.label(11))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            if let count {
                Text(String(format: "%02d", count))
                    .font(.label(11))
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .padding(.horizontal, 4)
    }
}
