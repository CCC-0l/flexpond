import Foundation

public enum LiftCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case bodybuilding = "Bodybuilding"
    case powerlifting = "Powerlifting"
    case toning = "Toning"

    public var id: String { rawValue }
    public var badge: String {
        switch self {
        case .bodybuilding: return "BB"
        case .powerlifting: return "PL"
        case .toning: return "TO"
        }
    }
    public var subtitle: String {
        switch self {
        case .bodybuilding: return "Hypertrophy focus · higher volume"
        case .powerlifting: return "Squat · Bench · Deadlift"
        case .toning: return "Lighter load · higher reps"
        }
    }
    public var repRange: String {
        switch self {
        case .bodybuilding: return "8–15 reps"
        case .powerlifting: return "1–6 reps"
        case .toning: return "12–20 reps"
        }
    }
    public var restRange: String {
        switch self {
        case .bodybuilding: return "60–90s"
        case .powerlifting: return "2–4 min"
        case .toning: return "30–60s"
        }
    }
}

public enum CardioCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case walk = "Walk"
    case run = "Run"
    case hit = "HIT"

    public var id: String { rawValue }
    public var badge: String {
        switch self {
        case .walk: return "WK"
        case .run: return "RN"
        case .hit: return "HI"
        }
    }
    public var subtitle: String {
        switch self {
        case .walk: return "Zone 2 · low intensity"
        case .run: return "Steady state or intervals"
        case .hit: return "High Intensity Training"
        }
    }
}

public enum TrainingFrequency: String, CaseIterable, Codable, Sendable {
    case fourDay = "4"
    case sixDay = "6"

    public var days: Int { self == .fourDay ? 4 : 6 }
    public var label: String { "\(rawValue)-day split" }
}

/// A single exercise line, e.g. "Bench Press 4x8-10" parsed into name + sets/reps.
public struct ExerciseEntry: Codable, Sendable, Identifiable, Equatable {
    public var id: String { name + setsReps }
    public let name: String
    public let setsReps: String

    /// Mirrors the `dc.html` Logic's `parseItem`: splits a trailing "NxM-N" token off the name.
    public init(raw: String) {
        if let match = raw.range(of: #"\s\d+x.*$"#, options: .regularExpression) {
            var sr = raw[match].trimmingCharacters(in: .whitespaces)
            if let xIndex = sr.firstIndex(of: "x") {
                sr.replaceSubrange(xIndex...xIndex, with: " × ")
            }
            self.name = String(raw[raw.startIndex..<match.lowerBound]).trimmingCharacters(in: .whitespaces)
            self.setsReps = sr
        } else {
            self.name = raw
            self.setsReps = ""
        }
    }
}

public struct TrainingDay: Codable, Sendable, Identifiable, Equatable {
    public let id = UUID()
    public let label: String
    public let items: [ExerciseEntry]

    public init(label: String, items: [String]) {
        self.label = label
        self.items = items.map(ExerciseEntry.init(raw:))
    }

    private enum CodingKeys: String, CodingKey { case label, items }
}

public struct ProgramVariant: Codable, Sendable, Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let days: [TrainingDay]

    public init(name: String, description: String, days: [TrainingDay]) {
        self.name = name
        self.description = description
        self.days = days
    }

    private enum CodingKeys: String, CodingKey { case name, description, days }
}
