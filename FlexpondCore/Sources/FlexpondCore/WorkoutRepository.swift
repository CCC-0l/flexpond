import Foundation

/// The seam between the app and a backend. Everything the UI needs is async
/// so a real networked implementation (URLSession/whatever) can replace
/// `LocalWorkoutRepository` without touching any view or view model code.
/// Covers the app's full local persistence surface (workouts, diet, walk
/// goal, the non-secret Oura snapshot) — the Oura PAT itself never passes
/// through here, it stays in Keychain via `OuraService`.
public protocol WorkoutRepository: Sendable {
    func fetchPlan() async throws -> [PlanItem]
    func savePlan(_ plan: [PlanItem]) async throws
    func fetchReadiness() async throws -> ReadinessData
    func fetchPhysiqueEntries() async throws -> [PhysiqueEntry]
    func savePhysiqueEntries(_ entries: [PhysiqueEntry]) async throws
    func fetchDietProfile() async throws -> DietProfile?
    func saveDietProfile(_ profile: DietProfile) async throws
    func fetchMealLog() async throws -> [MealEntry]
    func saveMealLog(_ log: [MealEntry]) async throws
    func fetchWalkGoal() async throws -> Int?
    func saveWalkGoal(_ goal: Int) async throws
    func fetchOuraSnapshot() async throws -> OuraSnapshot?
    func saveOuraSnapshot(_ snapshot: OuraSnapshot?) async throws
}

/// UserDefaults + JSON-backed persistence, seeded with the design handoff's
/// 6 sample physique entries (real bundled photos) on first launch. Simple
/// on purpose — a single-user learning app doesn't need Core Data.
public actor LocalWorkoutRepository: WorkoutRepository {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let plan = "flexpond.plan"
        static let physiqueEntries = "flexpond.physiqueEntries"
        static let dietProfile = "flexpond.dietProfile"
        static let mealLog = "flexpond.mealLog"
        static let walkGoal = "flexpond.walkGoal"
        static let ouraSnapshot = "flexpond.ouraSnapshot"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: Plan

    public func fetchPlan() async throws -> [PlanItem] {
        load([PlanItem].self, forKey: Key.plan) ?? []
    }

    public func savePlan(_ plan: [PlanItem]) async throws {
        save(plan, forKey: Key.plan)
    }

    // MARK: Readiness (static mock — used only pre-Oura-connect)

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

    // MARK: Physique

    public func fetchPhysiqueEntries() async throws -> [PhysiqueEntry] {
        load([PhysiqueEntry].self, forKey: Key.physiqueEntries) ?? Self.seededPhysiqueEntries
    }

    public func savePhysiqueEntries(_ entries: [PhysiqueEntry]) async throws {
        save(entries, forKey: Key.physiqueEntries)
    }

    // MARK: Diet

    public func fetchDietProfile() async throws -> DietProfile? {
        load(DietProfile.self, forKey: Key.dietProfile)
    }

    public func saveDietProfile(_ profile: DietProfile) async throws {
        save(profile, forKey: Key.dietProfile)
    }

    public func fetchMealLog() async throws -> [MealEntry] {
        load([MealEntry].self, forKey: Key.mealLog) ?? []
    }

    public func saveMealLog(_ log: [MealEntry]) async throws {
        save(log, forKey: Key.mealLog)
    }

    // MARK: Walk goal

    public func fetchWalkGoal() async throws -> Int? {
        let value = defaults.integer(forKey: Key.walkGoal)
        return value == 0 ? nil : value
    }

    public func saveWalkGoal(_ goal: Int) async throws {
        defaults.set(goal, forKey: Key.walkGoal)
    }

    // MARK: Oura snapshot (non-secret only — PAT lives in Keychain via OuraService)

    public func fetchOuraSnapshot() async throws -> OuraSnapshot? {
        load(OuraSnapshot.self, forKey: Key.ouraSnapshot)
    }

    public func saveOuraSnapshot(_ snapshot: OuraSnapshot?) async throws {
        guard let snapshot else {
            defaults.removeObject(forKey: Key.ouraSnapshot)
            return
        }
        save(snapshot, forKey: Key.ouraSnapshot)
    }

    // MARK: Helpers

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    /// The 6 sample entries from the design handoff (`dc.html`'s
    /// `physEntries`/`PHYS_PHOTOS`), each with real bundled front/side/back
    /// photos.
    private static let seededPhysiqueEntries: [PhysiqueEntry] = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        func date(_ s: String) -> Date { formatter.date(from: s) ?? Date() }

        func photos(_ assetPrefix: String) -> [String: String] {
            [
                PhysiquePose.front.rawValue: "phys-\(assetPrefix)-front",
                PhysiquePose.back.rawValue: "phys-\(assetPrefix)-back",
            ]
        }

        // A plausible steady lean-bulk progression so Timeline/Compare
        // deltas have real numbers to show before the user logs their own.
        return [
            PhysiqueEntry(id: "day1", label: "Day 1", date: date("Dec 10, 2025"), photoFileNames: photos("day1"), weightPounds: 178),
            PhysiqueEntry(id: "wk6", label: "Week 6", date: date("Jan 21, 2026"), photoFileNames: photos("6wk"), weightPounds: 180),
            PhysiqueEntry(id: "wk12", label: "Week 12", date: date("Mar 4, 2026"), photoFileNames: photos("12wk"), weightPounds: 183),
            PhysiqueEntry(id: "wk18", label: "Week 18", date: date("Apr 15, 2026"), photoFileNames: photos("18wk"), weightPounds: 186),
            PhysiqueEntry(id: "wk24", label: "Week 24", date: date("May 27, 2026"), photoFileNames: photos("24wk"), weightPounds: 189),
            PhysiqueEntry(id: "wk30", label: "Week 30", date: date("Jul 8, 2026"), photoFileNames: photos("30wk"), weightPounds: 192),
        ]
    }()
}
