import SwiftUI
import FlexpondCore

struct WorkoutBrowseView: View {
    @ObservedObject var vm: AppViewModel

    private var liftingCategories: [ProgramCategory] {
        ProgramCategory.allCases.filter { $0.section == .lifting }
    }
    // Moderate-Intensity Cardio before HIT, matching the browse order in the design.
    private let cardioProgramCategories: [ProgramCategory] = [.moderateIntensityCardio, .hit]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Lifting", count: liftingCategories.count)
            ForEach(liftingCategories) { category in
                FlexpondCard(badge: category.badge, title: category.rawValue, subtitle: category.subtitle) {
                    vm.openCategory(.program(category))
                }
            }

            SectionHeader(title: "Cardio", count: cardioProgramCategories.count + 1)
                .padding(.top, 12)
            FlexpondCard(badge: "WK", title: "Walk", subtitle: "Zone 2 · low intensity") {
                vm.openCategory(.walk)
            }
            ForEach(cardioProgramCategories) { category in
                FlexpondCard(badge: category.badge, title: category.rawValue, subtitle: category.subtitle) {
                    vm.openCategory(.program(category))
                }
            }
        }
        .padding(.top, 6)
    }
}
