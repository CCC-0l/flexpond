import Foundation

/// An entry in the user's active plan on the Home tab — either a lifting
/// program they started, or a standing cardio goal (currently just Walk).
public enum PlanItem: Codable, Sendable, Identifiable, Equatable {
    case lift(id: String, category: LiftCategory, frequency: TrainingFrequency, variantIndex: Int)
    case walk(id: String, dailyStepGoal: Int)

    public var id: String {
        switch self {
        case .lift(let id, _, _, _): return id
        case .walk(let id, _): return id
        }
    }

    public static func liftID(category: LiftCategory, frequency: TrainingFrequency, variantIndex: Int) -> String {
        "lift-\(category.rawValue)-\(frequency.rawValue)-\(variantIndex)"
    }
}
