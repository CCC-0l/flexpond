import SwiftUI
import FlexpondCore

struct WorkoutBrowseView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Lifting", count: LiftCategory.allCases.count)
            ForEach(LiftCategory.allCases) { category in
                FlexpondCard(badge: category.badge, title: category.rawValue, subtitle: category.subtitle) {
                    vm.openCategory(.lift(category))
                }
            }

            SectionHeader(title: "Cardio", count: CardioCategory.allCases.count)
                .padding(.top, 12)
            ForEach(CardioCategory.allCases) { category in
                FlexpondCard(badge: category.badge, title: category.rawValue, subtitle: category.subtitle) {
                    vm.openCategory(.cardio(category))
                }
            }
        }
        .padding(.top, 6)
    }
}
