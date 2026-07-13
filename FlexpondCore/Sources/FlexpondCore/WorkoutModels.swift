import Foundation

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
