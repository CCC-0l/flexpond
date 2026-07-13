import Foundation

public enum FocusSeverity: String, Codable, Sendable {
    case attention
    case good
}

public struct ReadinessFocusArea: Codable, Sendable, Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let severity: FocusSeverity
    public let detail: String
    /// Small daily-bar sparkline, one value per recent day, 0...1.
    public let trend: [Double]

    public init(title: String, severity: FocusSeverity, detail: String, trend: [Double]) {
        self.title = title
        self.severity = severity
        self.detail = detail
        self.trend = trend
    }

    private enum CodingKeys: String, CodingKey { case title, severity, detail, trend }
}

public struct ReadinessContributor: Codable, Sendable, Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let value: String
    public let unit: String
    public let delta: String
    public let isPositive: Bool
    public let footnote: String
    /// Sparkline sample points, arbitrary scale (rendered relative to its own min/max).
    public let series: [Double]

    public init(title: String, value: String, unit: String, delta: String, isPositive: Bool, footnote: String, series: [Double]) {
        self.title = title
        self.value = value
        self.unit = unit
        self.delta = delta
        self.isPositive = isPositive
        self.footnote = footnote
        self.series = series
    }

    private enum CodingKeys: String, CodingKey { case title, value, unit, delta, isPositive, footnote, series }
}

public struct ReadinessData: Codable, Sendable, Equatable {
    public let score: Int
    public let headline: String
    public let summary: String
    public let focusAreas: [ReadinessFocusArea]
    public let contributors: [ReadinessContributor]

    public init(score: Int, headline: String, summary: String, focusAreas: [ReadinessFocusArea], contributors: [ReadinessContributor]) {
        self.score = score
        self.headline = headline
        self.summary = summary
        self.focusAreas = focusAreas
        self.contributors = contributors
    }
}
