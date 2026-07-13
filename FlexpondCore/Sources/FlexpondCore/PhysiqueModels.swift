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

    public init(id: String, label: String, date: Date) {
        self.id = id
        self.label = label
        self.date = date
    }
}
