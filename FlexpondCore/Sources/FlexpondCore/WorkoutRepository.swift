import Foundation

/// The seam between the app and a backend. Everything the UI needs is async
/// so a real networked implementation (URLSession/whatever) can replace
/// `MockWorkoutRepository` without touching any view or view model code.
public protocol WorkoutRepository: Sendable {
    func fetchPlan() async throws -> [PlanItem]
    func savePlan(_ plan: [PlanItem]) async throws
    func fetchReadiness() async throws -> ReadinessData
    func fetchPhysiqueEntries() async throws -> [PhysiqueEntry]
    func addPhysiqueEntry(_ entry: PhysiqueEntry) async throws
}

/// In-memory stand-in so the app is fully interactive before a real backend
/// exists. Construct `AppViewModel(repository: MockWorkoutRepository())` today;
/// swap in a real type later with no other code changes.
public actor MockWorkoutRepository: WorkoutRepository {
    private var plan: [PlanItem] = []
    private var physiqueEntries: [PhysiqueEntry]

    public init() {
        let calendar = Calendar.current
        let now = Date()
        physiqueEntries = [
            PhysiqueEntry(id: "e1", label: "Starting point", date: calendar.date(byAdding: .day, value: -63, to: now) ?? now),
            PhysiqueEntry(id: "e2", label: "6-week check", date: calendar.date(byAdding: .day, value: -21, to: now) ?? now),
            PhysiqueEntry(id: "e3", label: "Latest", date: now),
        ]
    }

    public func fetchPlan() async throws -> [PlanItem] { plan }

    public func savePlan(_ plan: [PlanItem]) async throws { self.plan = plan }

    public func fetchReadiness() async throws -> ReadinessData {
        ReadinessData(
            score: 82,
            headline: "Primed to train",
            summary: "Recovery is strong. Sleep regularity and activity balance are the two things to watch today.",
            focusAreas: [
                ReadinessFocusArea(
                    title: "Sleep regularity",
                    severity: .attention,
                    detail: "Bed and wake times swung ±92 min across the week. Even with enough total sleep, irregular timing holds your score back.",
                    trend: [0.52, 0.50, 0.46, 0.54, 0.44, 0.48, 0.52]
                ),
                ReadinessFocusArea(
                    title: "Activity balance",
                    severity: .attention,
                    detail: "Load over the last 2 weeks is 18% above your 2-month average — ease back to avoid overtraining.",
                    trend: [0.82, 0.62]
                ),
            ],
            contributors: [
                ReadinessContributor(title: "Resting HR", value: "48", unit: "bpm", delta: "−3", isPositive: true, footnote: "7-night avg 51", series: [17, 19, 16, 18, 15, 17, 14, 16, 13, 15, 12, 13, 11]),
                ReadinessContributor(title: "HRV balance", value: "62", unit: "ms", delta: "+4", isPositive: true, footnote: "baseline 58 ms", series: [20, 18, 19, 16, 17, 14, 15, 12, 14, 11, 12, 9, 10]),
                ReadinessContributor(title: "Body temp", value: "+0.2", unit: "°C", delta: "±0", isPositive: true, footnote: "vs personal baseline", series: [16, 15, 16, 14, 15, 13, 14, 15, 13, 14, 13]),
                ReadinessContributor(title: "Recovery", value: "6.2", unit: "h", delta: "early", isPositive: true, footnote: "HR low reached early", series: [20, 16, 12, 10, 9, 9, 10, 10, 11, 10, 11]),
                ReadinessContributor(title: "Sleep", value: "7:42", unit: "h", delta: "+34m", isPositive: true, footnote: "norm 7:08", series: [14, 16, 13, 15, 12, 14, 11, 13, 10, 12, 9]),
                ReadinessContributor(title: "Sleep balance", value: "−0.4", unit: "h debt", delta: "ok", isPositive: true, footnote: "14-night trend", series: [15, 13, 16, 14, 17, 15, 13, 16, 14, 15, 14]),
                ReadinessContributor(title: "Prev. activity", value: "410", unit: "kcal", delta: "−20", isPositive: true, footnote: "avg 430 kcal", series: [16, 14, 17, 15, 13, 16, 14, 15, 13, 15, 14]),
            ]
        )
    }

    public func fetchPhysiqueEntries() async throws -> [PhysiqueEntry] { physiqueEntries }

    public func addPhysiqueEntry(_ entry: PhysiqueEntry) async throws {
        physiqueEntries.append(entry)
    }
}
