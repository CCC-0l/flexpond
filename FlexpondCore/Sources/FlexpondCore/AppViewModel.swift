import Foundation
import Combine

// MARK: - View-friendly derived data

public struct WeekDayCell: Identifiable, Sendable {
    public let id: Int // Monday = 0 ... Sunday = 6
    public let abbreviation: String
    public let isToday: Bool
    public let isSelected: Bool
    public let isRestDay: Bool
}

/// A row on the Home tab's plan list. Read-only schedule info only — the
/// redesign dropped per-exercise completion tracking entirely (no
/// checkboxes, no "Complete session", no progress bars).
public struct PlanRow: Identifiable, Sendable {
    public let id: String
    public let badge: String
    public let title: String
    public let subtitle: String
    /// "Today · Upper A" / "Rest day today" / "" (Walk has none).
    public let todayLabel: String
}

public struct VariantOption: Identifiable, Sendable {
    public let id: Int
    public let variant: ProgramVariant
    public let isSelected: Bool
    public let tags: [String]
}

public struct OuraMetricItem: Identifiable, Sendable {
    public var id: String { label }
    public let label: String
    public let score: Int
    public let status: ReadinessStatus
}

public struct CompareOption: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let date: Date
    public let isSelected: Bool
    public let badgeNumber: Int?
}

public struct DietSummary: Sendable {
    public let targetCalories: Int
    public let consumedCalories: Int
    public let remainingCalories: Int
    public let calorieProgress: Double
    public let proteinTarget: Int
    public let carbTarget: Int
    public let fatTarget: Int
    public let proteinConsumed: Int
    public let carbConsumed: Int
    public let fatConsumed: Int
    public let proteinProgress: Double
    public let carbProgress: Double
    public let fatProgress: Double
}

// MARK: - AppViewModel

@MainActor
public final class AppViewModel: ObservableObject {
    private let repository: WorkoutRepository
    private let ouraService: OuraService
    private let calendar: Calendar
    private let now: () -> Date

    // Tab / navigation
    @Published public var selectedTab: AppTab = .home
    @Published public var workoutScreen: WorkoutScreen = .browse
    @Published public var selectedCategory: WorkoutCategory?
    @Published public var frequency: TrainingFrequency = .fourDay
    @Published public var variantIndex: Int = 0
    @Published public var selectedWeekday: Int?

    // Plan
    @Published public private(set) var plan: [PlanItem] = []

    // Walk goal
    @Published public var walkGoal: Int = 10_000
    @Published public var walkGoalSaved: Bool = false

    // Readiness (static mock, used only pre-Oura-connect)
    @Published public private(set) var readiness: ReadinessData?

    // Oura Ring
    @Published public var ouraConnected: Bool = false
    @Published public var ouraConnectOpen: Bool = false
    @Published public var ouraToken: String = ""
    @Published public private(set) var ouraSyncing: Bool = false
    @Published public private(set) var ouraSyncError: String?
    @Published public private(set) var ouraScore: Int?
    @Published public private(set) var ouraContributors: OuraContributors?
    @Published public private(set) var ouraDay: String?
    @Published public private(set) var ouraSyncedAt: Date?

    // Physique
    @Published public private(set) var physiqueEntries: [PhysiqueEntry] = []
    @Published public var physiqueViewMode: PhysiqueViewMode = .timeline
    @Published public private(set) var selectedEntryIDs: [String] = []

    // Diet
    @Published public var dietProfile: DietProfile = DietProfile()
    @Published public var dietScreen: DietScreen = .setup
    @Published public var dietAdvancedOpen: Bool = false
    @Published public private(set) var mealLog: [MealEntry] = []
    @Published public var newMealName: String = ""
    @Published public var newMealCalories: String = ""
    @Published public var newMealProtein: String = ""
    @Published public var newMealCarb: String = ""
    @Published public var newMealFat: String = ""

    public init(
        repository: WorkoutRepository = LocalWorkoutRepository(),
        ouraService: OuraService = OuraService(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.ouraService = ouraService
        self.calendar = calendar
        self.now = now
        Task { await load() }
    }

    public func load() async {
        async let planTask = repository.fetchPlan()
        async let readinessTask = repository.fetchReadiness()
        async let physiqueTask = repository.fetchPhysiqueEntries()
        async let dietProfileTask = repository.fetchDietProfile()
        async let mealLogTask = repository.fetchMealLog()
        async let walkGoalTask = repository.fetchWalkGoal()
        async let ouraSnapshotTask = repository.fetchOuraSnapshot()

        if let plan = try? await planTask { self.plan = plan }
        if let readiness = try? await readinessTask { self.readiness = readiness }
        if let entries = try? await physiqueTask { self.physiqueEntries = entries }
        if let profile = try? await dietProfileTask {
            self.dietProfile = profile
            self.dietScreen = .dashboard
        }
        if let log = try? await mealLogTask { self.mealLog = log }
        if let goal = try? await walkGoalTask { self.walkGoal = goal }
        if let snapshot = try? await ouraSnapshotTask, ouraService.loadToken() != nil {
            ouraConnected = true
            ouraScore = snapshot.score
            ouraContributors = snapshot.contributors
            ouraDay = snapshot.day
            ouraSyncedAt = snapshot.syncedAt
        }
    }

    // MARK: - Derived state: Workout

    public var todayWeekday: Int { WorkoutSchedule.mondayIndexedWeekday(from: now(), calendar: calendar) }
    public var effectiveWeekday: Int { selectedWeekday ?? todayWeekday }

    public var activeVariants: [ProgramVariant] {
        guard case .program(let category) = selectedCategory else { return [] }
        return WorkoutLibrary.variants(for: category, frequency: frequency)
    }

    public var activeVariant: ProgramVariant? {
        let variants = activeVariants
        guard variantIndex < variants.count else { return variants.first }
        return variants[variantIndex]
    }

    public var selectedTrainingDayIndex: Int? {
        WorkoutSchedule.trainingDayIndex(frequency: frequency, weekday: effectiveWeekday)
    }

    public var selectedTrainingDay: TrainingDay? {
        guard let idx = selectedTrainingDayIndex, let variant = activeVariant, idx < variant.days.count else { return nil }
        return variant.days[idx]
    }

    public var isRestDay: Bool { selectedTrainingDay == nil }

    /// "Rest 60–90s between sets" / "...between efforts" for cardio.
    public var restLine: String {
        guard case .program(let category) = selectedCategory else { return "" }
        return "Rest \(category.restRange) \(category.restSuffix)"
    }

    public var weekStrip: [WeekDayCell] {
        let sched = WorkoutSchedule.dayIndices(for: frequency)
        return (0..<7).map { i in
            let dayIdx = sched[i]
            let isRest = dayIdx < 0 || (activeVariant.map { dayIdx >= $0.days.count } ?? true)
            return WeekDayCell(
                id: i,
                abbreviation: WorkoutSchedule.weekdayAbbreviations[i],
                isToday: i == todayWeekday,
                isSelected: i == effectiveWeekday,
                isRestDay: isRest
            )
        }
    }

    public var variantOptions: [VariantOption] {
        guard case .program(let category) = selectedCategory else { return [] }
        let tags = [frequency.rawValue + " days/wk", category.repRange, category.restRange + " rest"]
        return activeVariants.enumerated().map { i, v in
            VariantOption(id: i, variant: v, isSelected: i == variantIndex, tags: tags)
        }
    }

    public var planRows: [PlanRow] {
        plan.map { item in
            switch item {
            case .walk(let id, let goal):
                return PlanRow(id: id, badge: "WK", title: "Walk", subtitle: "\(goal.formatted()) steps / day", todayLabel: "")
            case .program(let id, let category, let freq, let variantIdx):
                let variants = WorkoutLibrary.variants(for: category, frequency: freq)
                let variant = variantIdx < variants.count ? variants[variantIdx] : variants.first
                let sched = WorkoutSchedule.dayIndices(for: freq)
                let todayDi = sched[todayWeekday]
                let restToday = todayDi < 0 || (variant.map { todayDi >= $0.days.count } ?? true)
                let todayLabel = variant != nil ? (restToday ? "Rest day today" : "Today · \(variant!.days[todayDi].label)") : ""
                return PlanRow(
                    id: id,
                    badge: category.badge,
                    title: category.rawValue,
                    subtitle: "\(variant?.name ?? "") · \(freq.rawValue)-day",
                    todayLabel: todayLabel
                )
            }
        }
    }

    // MARK: - Derived state: Home readiness teaser

    public var homeReadinessScore: Int { ouraConnected ? (ouraScore ?? 0) : 82 }

    public var homeReadinessLabel: String {
        guard ouraConnected, let score = ouraScore else { return "Primed to train" }
        if score >= 85 { return "Primed to train" }
        if score >= 70 { return "Ready to train" }
        return "Take it easy today"
    }

    // MARK: - Actions: Workout

    public func selectTab(_ tab: AppTab) { selectedTab = tab }

    public func goAddWorkout() {
        selectedTab = .workout
        workoutScreen = .browse
    }

    public func openCategory(_ category: WorkoutCategory) {
        selectedCategory = category
        variantIndex = 0
        selectedWeekday = nil
        workoutScreen = .detail
    }

    public func selectFrequency(_ freq: TrainingFrequency) {
        frequency = freq
        variantIndex = 0
        selectedWeekday = nil
    }

    public func selectVariant(_ index: Int) {
        variantIndex = index
        selectedWeekday = nil
    }

    public func startProgram() {
        guard case .program(let category) = selectedCategory else { return }
        let id = PlanItem.programID(category: category, frequency: frequency, variantIndex: variantIndex)
        if !plan.contains(where: { $0.id == id }) {
            plan.append(.program(id: id, category: category, frequency: frequency, variantIndex: variantIndex))
            persistPlan()
        }
        selectedWeekday = nil
        workoutScreen = .today
    }

    public func openPlanRow(_ row: PlanRow) {
        guard let item = plan.first(where: { $0.id == row.id }) else { return }
        switch item {
        case .program(_, let category, let freq, let variantIdx):
            selectedCategory = .program(category)
            frequency = freq
            variantIndex = variantIdx
            selectedWeekday = nil
            selectedTab = .workout
            workoutScreen = .today
        case .walk:
            selectedCategory = .walk
            selectedTab = .workout
            workoutScreen = .detail
        }
    }

    public func removeFromPlan(_ id: String) {
        plan.removeAll { $0.id == id }
        persistPlan()
    }

    public func goBack() {
        workoutScreen = workoutScreen == .today ? .detail : .browse
    }

    public func goBrowse() { workoutScreen = .browse }

    public func selectWeekday(_ i: Int) { selectedWeekday = i }

    public func setWalkGoal(_ value: Int) {
        walkGoal = value
        walkGoalSaved = false
    }

    public func saveWalkGoal() {
        if let existing = plan.first(where: { if case .walk = $0 { return true } else { return false } }) {
            if let index = plan.firstIndex(where: { $0.id == existing.id }) {
                plan[index] = .walk(id: existing.id, dailyStepGoal: walkGoal)
            }
        } else {
            plan.append(.walk(id: "walk", dailyStepGoal: walkGoal))
        }
        walkGoalSaved = true
        persistPlan()
        let goal = walkGoal
        Task { try? await repository.saveWalkGoal(goal) }
    }

    private func persistPlan() {
        let snapshot = plan
        Task { try? await repository.savePlan(snapshot) }
    }

    // MARK: - Actions: Oura

    public func openOuraConnect() {
        ouraConnectOpen = true
        ouraSyncError = nil
    }

    public func closeOuraConnect() {
        ouraConnectOpen = false
        ouraSyncError = nil
    }

    public func connectOura() async {
        let token = ouraToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            ouraSyncError = "Paste your Personal Access Token first."
            return
        }
        ouraSyncing = true
        ouraSyncError = nil
        do {
            try ouraService.saveToken(token)
            let day = try await ouraService.fetchLatestReadiness()
            applyOuraDay(day)
            ouraConnectOpen = false
            ouraToken = ""
        } catch {
            ouraService.deleteToken()
            ouraSyncError = (error as? LocalizedError)?.errorDescription ?? "Couldn't connect to Oura — check your token and try again."
        }
        ouraSyncing = false
    }

    /// Refetches using the token already in Keychain — the "Sync" action on
    /// the connected status bar. Distinct from `connectOura()`, which needs
    /// a freshly-typed token; this needs none, so it doesn't reopen the form.
    public func syncOura() async {
        guard ouraService.loadToken() != nil else { return }
        ouraSyncing = true
        ouraSyncError = nil
        do {
            let day = try await ouraService.fetchLatestReadiness()
            applyOuraDay(day)
        } catch {
            ouraSyncError = (error as? LocalizedError)?.errorDescription ?? "Couldn't refresh from Oura — try again."
        }
        ouraSyncing = false
    }

    public func disconnectOura() {
        ouraService.deleteToken()
        ouraConnected = false
        ouraScore = nil
        ouraContributors = nil
        ouraDay = nil
        ouraSyncedAt = nil
        ouraConnectOpen = false
        Task { try? await repository.saveOuraSnapshot(nil) }
    }

    private func applyOuraDay(_ day: OuraReadinessDay) {
        ouraConnected = true
        ouraScore = day.score
        ouraContributors = day.contributors
        ouraDay = day.day
        ouraSyncedAt = now()
        let snapshot = OuraSnapshot(day: day, syncedAt: now())
        Task { try? await repository.saveOuraSnapshot(snapshot) }
    }

    public var ouraFocusItems: [OuraMetricItem] {
        sortedOuraContributors.prefix(2).map { OuraMetricItem(label: $0.label, score: $0.score, status: ReadinessStatus(score: $0.score)) }
    }

    public var ouraGridItems: [OuraMetricItem] {
        sortedOuraContributors.dropFirst(2).map { OuraMetricItem(label: $0.label, score: $0.score, status: ReadinessStatus(score: $0.score)) }
    }

    private var sortedOuraContributors: [(label: String, score: Int)] {
        guard let contributors = ouraContributors else { return [] }
        return contributors.all.sorted { $0.score < $1.score }
    }

    public var ouraSummaryLine: String {
        guard let syncedAt = ouraSyncedAt else { return "" }
        let mins = max(0, Int(now().timeIntervalSince(syncedAt) / 60))
        if mins < 1 { return "Synced just now" }
        if mins < 60 { return "Synced \(mins)m ago" }
        return "Synced \(mins / 60)h ago"
    }

    // MARK: - Actions: Physique

    public func setPhysiqueViewMode(_ mode: PhysiqueViewMode) { physiqueViewMode = mode }

    public func toggleCompareEntry(_ id: String) {
        if let idx = selectedEntryIDs.firstIndex(of: id) {
            selectedEntryIDs.remove(at: idx)
        } else if selectedEntryIDs.count < 2 {
            selectedEntryIDs.append(id)
        } else {
            selectedEntryIDs = [selectedEntryIDs[1], id]
        }
    }

    public var compareOptions: [CompareOption] {
        physiqueEntries.map { entry in
            let idx = selectedEntryIDs.firstIndex(of: entry.id)
            return CompareOption(id: entry.id, label: entry.label, date: entry.date, isSelected: idx != nil, badgeNumber: idx.map { $0 + 1 })
        }
    }

    public var compareEntryA: PhysiqueEntry? {
        selectedEntryIDs.first.flatMap { id in physiqueEntries.first { $0.id == id } }
    }

    public var compareEntryB: PhysiqueEntry? {
        guard selectedEntryIDs.count > 1 else { return nil }
        return physiqueEntries.first { $0.id == selectedEntryIDs[1] }
    }

    public func addPhysiqueEntry() {
        let entry = PhysiqueEntry(id: "e\(Int(now().timeIntervalSince1970))", label: "Set \(physiqueEntries.count + 1)", date: now())
        physiqueEntries.append(entry)
        physiqueViewMode = .timeline
        let snapshot = physiqueEntries
        Task { try? await repository.savePhysiqueEntries(snapshot) }
    }

    // MARK: - Derived state & actions: Diet

    public var macroTargets: MacroTargets { MacroCalculator.targets(for: dietProfile) }

    public var dietSummary: DietSummary {
        let targets = macroTargets
        let totals = mealLog.reduce((cals: 0, p: 0, c: 0, f: 0)) { acc, m in
            (acc.cals + m.calories, acc.p + m.proteinGrams, acc.c + m.carbGrams, acc.f + m.fatGrams)
        }
        func progress(_ value: Int, _ target: Int) -> Double { target == 0 ? 0 : min(1, Double(value) / Double(target)) }
        return DietSummary(
            targetCalories: targets.targetCalories,
            consumedCalories: totals.cals,
            remainingCalories: max(0, targets.targetCalories - totals.cals),
            calorieProgress: progress(totals.cals, targets.targetCalories),
            proteinTarget: targets.proteinGrams,
            carbTarget: targets.carbGrams,
            fatTarget: targets.fatGrams,
            proteinConsumed: totals.p,
            carbConsumed: totals.c,
            fatConsumed: totals.f,
            proteinProgress: progress(totals.p, targets.proteinGrams),
            carbProgress: progress(totals.c, targets.carbGrams),
            fatProgress: progress(totals.f, targets.fatGrams)
        )
    }

    public func toggleDietAdvanced() { dietAdvancedOpen.toggle() }

    public func calculateDiet() {
        dietScreen = .dashboard
        let profile = dietProfile
        Task { try? await repository.saveDietProfile(profile) }
    }

    public func editDietProfile() { dietScreen = .setup }

    public var canAddCustomMeal: Bool {
        !newMealName.trimmingCharacters(in: .whitespaces).isEmpty && (Int(newMealCalories) ?? 0) > 0
    }

    public func addQuickMeal(_ meal: QuickMeal) {
        mealLog.append(MealEntry(name: meal.name, calories: meal.calories, proteinGrams: meal.proteinGrams, carbGrams: meal.carbGrams, fatGrams: meal.fatGrams))
        persistMealLog()
    }

    public func addCustomMeal() {
        guard canAddCustomMeal else { return }
        mealLog.append(MealEntry(
            name: newMealName.trimmingCharacters(in: .whitespaces),
            calories: Int(newMealCalories) ?? 0,
            proteinGrams: Int(newMealProtein) ?? 0,
            carbGrams: Int(newMealCarb) ?? 0,
            fatGrams: Int(newMealFat) ?? 0
        ))
        newMealName = ""
        newMealCalories = ""
        newMealProtein = ""
        newMealCarb = ""
        newMealFat = ""
        persistMealLog()
    }

    public func removeMeal(_ id: String) {
        mealLog.removeAll { $0.id == id }
        persistMealLog()
    }

    private func persistMealLog() {
        let snapshot = mealLog
        Task { try? await repository.saveMealLog(snapshot) }
    }
}
