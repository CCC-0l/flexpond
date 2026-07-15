import Foundation

public enum PhysiquePose: String, CaseIterable, Codable, Sendable, Identifiable {
    case front, side, back
    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
}

public struct PhysiqueEntry: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let label: String
    public let date: Date
    /// Photo identifier keyed by `PhysiquePose.rawValue` — either a bundled
    /// resource name (the 6 sample entries seeded from the design handoff's
    /// `assets/`) or a user-captured photo's filename in the app's
    /// Documents directory (see `PhysiquePhotoCache` in the app target,
    /// which resolves either kind transparently). Missing a key means no
    /// photo has been captured yet for that pose. (Keyed by raw string
    /// rather than `PhysiquePose` directly so `Codable` always encodes it
    /// as a plain JSON object.)
    public let photoFileNames: [String: String]
    /// Self-reported at logging time. Optional — an entry can exist with
    /// photos but no weight logged, or vice versa.
    public let weightPounds: Int?

    public init(id: String, label: String, date: Date, photoFileNames: [String: String] = [:], weightPounds: Int? = nil) {
        self.id = id
        self.label = label
        self.date = date
        self.photoFileNames = photoFileNames
        self.weightPounds = weightPounds
    }

    public func photoFileName(for pose: PhysiquePose) -> String? {
        photoFileNames[pose.rawValue]
    }

    public func withWeightPounds(_ weightPounds: Int?) -> PhysiqueEntry {
        PhysiqueEntry(id: id, label: label, date: date, photoFileNames: photoFileNames, weightPounds: weightPounds)
    }

    public func withPhotoIdentifier(_ identifier: String, for pose: PhysiquePose) -> PhysiqueEntry {
        var names = photoFileNames
        names[pose.rawValue] = identifier
        return PhysiqueEntry(id: id, label: label, date: date, photoFileNames: names, weightPounds: weightPounds)
    }
}

/// Pure body-composition math, kept alongside `MacroCalculator` in spirit —
/// deterministic, easy to unit test, no view/state coupling.
public enum PhysiqueStats {
    /// Standard BMI: kg / m². Reuses the same lb→kg and inch→cm/m
    /// conversion constants as `MacroCalculator`.
    public static func bmi(weightPounds: Int, heightFeet: Int, heightInches: Int) -> Double? {
        let totalInches = Double(heightFeet * 12 + heightInches)
        guard totalInches > 0 else { return nil }
        let heightMeters = totalInches * 0.0254
        let weightKg = Double(weightPounds) * 0.453592
        return weightKg / (heightMeters * heightMeters)
    }
}
