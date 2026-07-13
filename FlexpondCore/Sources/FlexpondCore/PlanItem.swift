import Foundation

/// An entry in the user's active plan on the Home tab — either a program
/// they started (any of the 5 `ProgramCategory` values), or a standing
/// cardio goal (currently just Walk).
public enum PlanItem: Codable, Sendable, Identifiable, Equatable {
    case program(id: String, category: ProgramCategory, frequency: TrainingFrequency, variantIndex: Int)
    case walk(id: String, dailyStepGoal: Int)

    public var id: String {
        switch self {
        case .program(let id, _, _, _): return id
        case .walk(let id, _): return id
        }
    }

    public static func programID(category: ProgramCategory, frequency: TrainingFrequency, variantIndex: Int) -> String {
        "lift-\(category.rawValue)-\(frequency.rawValue)-\(variantIndex)"
    }
}
