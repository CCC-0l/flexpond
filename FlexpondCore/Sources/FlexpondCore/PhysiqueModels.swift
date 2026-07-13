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
    /// Bundled resource filename (without extension), keyed by
    /// `PhysiquePose.rawValue`, for the sample entries seeded from the
    /// design handoff's `assets/`. Empty for user-added entries until real
    /// photo capture is wired up. (Keyed by raw string rather than
    /// `PhysiquePose` directly so `Codable` always encodes it as a plain
    /// JSON object.)
    public let photoFileNames: [String: String]

    public init(id: String, label: String, date: Date, photoFileNames: [String: String] = [:]) {
        self.id = id
        self.label = label
        self.date = date
        self.photoFileNames = photoFileNames
    }

    public func photoFileName(for pose: PhysiquePose) -> String? {
        photoFileNames[pose.rawValue]
    }
}
