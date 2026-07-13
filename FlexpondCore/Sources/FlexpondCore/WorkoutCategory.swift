import Foundation

/// The 5 categories with full embedded program data (4-day/6-day × 3
/// variants each): the 3 lifting styles plus HIT and Moderate-Intensity
/// Cardio, which got the same full treatment as lifting in the redesign.
/// `Walk` is intentionally not part of this — it only ever has a
/// step-goal slider, never a program.
public enum ProgramCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case bodybuilding = "Bodybuilding"
    case powerlifting = "Powerlifting"
    case toning = "Toning"
    case hit = "HIT"
    case moderateIntensityCardio = "Moderate-Intensity Cardio"

    public var id: String { rawValue }

    public var section: WorkoutSection {
        switch self {
        case .bodybuilding, .powerlifting, .toning: return .lifting
        case .hit, .moderateIntensityCardio: return .cardio
        }
    }

    public var badge: String {
        switch self {
        case .bodybuilding: return "BB"
        case .powerlifting: return "PL"
        case .toning: return "TO"
        case .hit: return "HT"
        case .moderateIntensityCardio: return "MC"
        }
    }

    public var subtitle: String {
        switch self {
        case .bodybuilding: return "Hypertrophy focus · higher volume"
        case .powerlifting: return "Squat · Bench · Deadlift"
        case .toning: return "Lighter load · higher reps"
        case .hit: return "High Intensity Training"
        case .moderateIntensityCardio: return "Steady state or intervals"
        }
    }

    public var repRange: String {
        switch self {
        case .bodybuilding: return "8–15 reps"
        case .powerlifting: return "1–6 reps"
        case .toning: return "12–20 reps"
        case .hit: return "reps or timed"
        case .moderateIntensityCardio: return "duration-based"
        }
    }

    public var restRange: String {
        switch self {
        case .bodybuilding: return "60–90s"
        case .powerlifting: return "2–4 min"
        case .toning: return "30–60s"
        case .hit: return "15–30s"
        case .moderateIntensityCardio: return "1–2 min"
        }
    }

    /// "Rest 60–90s between sets" vs. "...between efforts" for cardio.
    public var restSuffix: String {
        self == .moderateIntensityCardio ? "between efforts" : "between sets"
    }
}

public enum WorkoutSection: Sendable {
    case lifting
    case cardio
}

/// A category the Workout tab can browse into: one of the 5 full-program
/// categories, or the simple step-goal Walk.
public enum WorkoutCategory: Equatable, Codable, Sendable {
    case program(ProgramCategory)
    case walk

    public var displayName: String {
        switch self {
        case .program(let c): return c.rawValue
        case .walk: return "Walk"
        }
    }
    public var badge: String {
        switch self {
        case .program(let c): return c.badge
        case .walk: return "WK"
        }
    }
    public var isProgram: Bool { if case .program = self { return true } else { return false } }
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
