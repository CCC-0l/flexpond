import Foundation

public enum WorkoutCategory: Equatable, Codable, Sendable {
    case lift(LiftCategory)
    case cardio(CardioCategory)

    public var displayName: String {
        switch self {
        case .lift(let c): return c.rawValue
        case .cardio(let c): return c.rawValue
        }
    }
    public var badge: String {
        switch self {
        case .lift(let c): return c.badge
        case .cardio(let c): return c.badge
        }
    }
    public var isLifting: Bool { if case .lift = self { return true } else { return false } }
}

public enum AppTab: String, CaseIterable, Sendable {
    case home, workout, diet, readiness, physique
    public var label: String { rawValue.capitalized }
}

public enum WorkoutScreen: Sendable {
    case browse
    case detail
    case today
}

public enum PhysiqueViewMode: Sendable {
    case timeline
    case compare
}
