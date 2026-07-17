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

/// Today's full schedule for one active program (lifting or cardio),
/// rendered directly on Home — no per-exercise completion tracking (the
/// redesign dropped that entirely: no checkboxes, no "Complete session",
/// no progress bars, read-only schedule info only).
public struct TodayScheduleItem: Identifiable, Sendable {
    public let id: String
    public let category: ProgramCategory
    public let badge: String
    public let variantName: String
    /// Training day label ("Upper A") or "Rest / Active Recovery".
    public let sessionLabel: String
    /// Today's weekday name, e.g. "Wednesday".
    public let dayName: String
    /// "Rest 60–90s between sets" — empty on a rest day.
    public let restLine: String
    /// Empty on a rest day.
    public let exercises: [ExerciseEntry]
    public let isRestDay: Bool
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
    @Published public var newEntryWeight: String = ""

    // Diet
    @Published public var dietProfile: DietProfile = DietProfile()
    @Published public var dietScreen: DietScreen = .setup
    @Published public var dietHistoryMode: DietHistoryMode = .today
    @Published public var dietAdvancedOpen: Bool = false
    @Published public private(set) var mealLog: [MealEntry] = []
    @Published public private(set) var savedFoods: [SavedFood] = []
    @Published public var newMealName: String = ""
    @Published public var newMealCalories: String = ""
    @Published public var newMealProtein: String = ""
    @Published public var newMealCarb: String = ""
    @Published public var newMealFat: String = ""
    @Published public var editingMealID: String?

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
        async let savedFoodsTask = repository.fetchSavedFoods()
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
        if let foods = try? await savedFoodsTask { self.savedFoods = foods }
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

    /// Today's schedule for the plan's active lifting program, if any —
    /// at most one, since `startProgram()` enforces one lifting + one
    /// cardio program at a time.
    public var todaysLiftingSchedule: TodayScheduleItem? {
        todaysScheduleItem(forSection: .lifting)
    }

    /// Today's schedule for the plan's active cardio program (HIT or
    /// Moderate-Intensity Cardio — Walk is handled separately via
    /// `walkPlanItem`, since it has no day-by-day schedule).
    public var todaysCardioSchedule: TodayScheduleItem? {
        todaysScheduleItem(forSection: .cardio)
    }

    /// The plan's Walk goal, if set — Walk has no day-by-day schedule, so
    /// Home renders it as a compact row rather than a full schedule card.
    public var walkPlanItem: (id: String, goal: Int)? {
        for item in plan {
            if case .walk(let id, let goal) = item { return (id, goal) }
        }
        return nil
    }

    private func todaysScheduleItem(forSection section: WorkoutSection) -> TodayScheduleItem? {
        guard let item = plan.first(where: {
            if case .program(_, let category, _, _) = $0 { return category.section == section }
            return false
        }), case .program(let id, let category, let freq, let variantIdx) = item else { return nil }

        let variants = WorkoutLibrary.variants(for: category, frequency: freq)
        let variant = variantIdx < variants.count ? variants[variantIdx] : variants.first
        let sched = WorkoutSchedule.dayIndices(for: freq)
        let todayDi = sched[todayWeekday]
        let isRest = todayDi < 0 || (variant.map { todayDi >= $0.days.count } ?? true)
        let day = isRest ? nil : variant?.days[todayDi]

        return TodayScheduleItem(
            id: id,
            category: category,
            badge: category.badge,
            variantName: variant?.name ?? "",
            sessionLabel: day?.label ?? "Rest / Active Recovery",
            dayName: WorkoutSchedule.weekdayNames[todayWeekday],
            restLine: isRest ? "" : "Rest \(category.restRange) \(category.restSuffix)",
            exercises: day?.items ?? [],
            isRestDay: isRest
        )
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
            // Only one lifting + one cardio program at a time — starting a
            // new one replaces whatever else was in that section, so Home's
            // "today" view never has to stack multiple schedules per section.
            plan.removeAll { item in
                if case .program(_, let existing, _, _) = item { return existing.section == category.section }
                return false
            }
            plan.append(.program(id: id, category: category, frequency: frequency, variantIndex: variantIndex))
            persistPlan()
        }
        selectedWeekday = nil
        workoutScreen = .today
    }

    /// Opens the Workout tab's Today screen for whichever program is in
    /// `section` — used by Home's lifting/cardio schedule cards.
    private func openTodayScheduleItem(forSection section: WorkoutSection) {
        guard let item = plan.first(where: {
            if case .program(_, let category, _, _) = $0 { return category.section == section }
            return false
        }), case .program(_, let category, let freq, let variantIdx) = item else { return }
        selectedCategory = .program(category)
        frequency = freq
        variantIndex = variantIdx
        selectedWeekday = nil
        selectedTab = .workout
        workoutScreen = .today
    }

    public func openLiftingToday() { openTodayScheduleItem(forSection: .lifting) }
    public func openCardioToday() { openTodayScheduleItem(forSection: .cardio) }

    public func openWalk() {
        selectedCategory = .walk
        selectedTab = .workout
        workoutScreen = .detail
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

    /// Called whenever the app becomes active (cold launch or returning
    /// from background) so the score is fresh without the user having to
    /// visit Readiness and tap Sync. Checks Keychain directly rather than
    /// `ouraConnected` so it works correctly even if this fires before
    /// `load()` has finished restoring the cached snapshot.
    public func refreshOuraIfConnected() {
        guard ouraService.loadToken() != nil else { return }
        Task { await syncOura() }
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

    /// Absolute pull time, e.g. "Jul 13, 3:55 PM" — the relative
    /// "Xm ago" line in the status bar goes stale-looking fast; this is
    /// the unambiguous "when was this actually fetched" answer.
    public var ouraSyncedAtFormatted: String {
        guard let syncedAt = ouraSyncedAt else { return "" }
        return syncedAt.formatted(date: .abbreviated, time: .shortened)
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
        let entry = PhysiqueEntry(
            id: "e\(Int(now().timeIntervalSince1970))",
            label: "Set \(physiqueEntries.count + 1)",
            date: now(),
            weightPounds: Int(newEntryWeight)
        )
        physiqueEntries.append(entry)
        physiqueViewMode = .timeline
        newEntryWeight = ""
        persistPhysiqueEntries()
    }

    public func updateEntryWeight(_ id: String, weightPounds: Int?) {
        guard let index = physiqueEntries.firstIndex(where: { $0.id == id }) else { return }
        physiqueEntries[index] = physiqueEntries[index].withWeightPounds(weightPounds)
        persistPhysiqueEntries()
    }

    /// Records that a photo was captured for `pose` on the given entry.
    /// `identifier` is an opaque filename the app-target view layer already
    /// saved to disk (via `PhysiquePhotoCache`) — this just updates which
    /// identifier the entry points at; FlexpondCore itself has no UIKit/
    /// file-I/O dependency.
    public func setPhotoIdentifier(_ identifier: String, for pose: PhysiquePose, entryID: String) {
        guard let index = physiqueEntries.firstIndex(where: { $0.id == entryID }) else { return }
        physiqueEntries[index] = physiqueEntries[index].withPhotoIdentifier(identifier, for: pose)
        persistPhysiqueEntries()
    }

    public func deletePhysiqueEntry(_ id: String) {
        physiqueEntries.removeAll { $0.id == id }
        selectedEntryIDs.removeAll { $0 == id }
        persistPhysiqueEntries()
    }

    private func persistPhysiqueEntries() {
        let snapshot = physiqueEntries
        Task { try? await repository.savePhysiqueEntries(snapshot) }
    }

    /// BMI for a given entry, using the height already captured in
    /// `dietProfile` — nil if the entry has no logged weight or no height
    /// has been set up yet (Diet profile untouched).
    public func bmi(for entry: PhysiqueEntry) -> Double? {
        guard let weight = entry.weightPounds else { return nil }
        return PhysiqueStats.bmi(weightPounds: weight, heightFeet: dietProfile.heightFeet, heightInches: dietProfile.heightInches)
    }

    /// Weight change vs. the chronologically previous entry (by `date`,
    /// not array order) — nil for the first entry, or if either entry is
    /// missing a logged weight.
    public func weightDelta(for entry: PhysiqueEntry) -> Int? {
        let sorted = physiqueEntries.sorted { $0.date < $1.date }
        guard let index = sorted.firstIndex(where: { $0.id == entry.id }), index > 0,
              let currentWeight = entry.weightPounds,
              let previousWeight = sorted[index - 1].weightPounds else { return nil }
        return currentWeight - previousWeight
    }

    /// BMI change vs. the chronologically previous entry — nil under the
    /// same conditions as `weightDelta(for:)`.
    public func bmiDelta(for entry: PhysiqueEntry) -> Double? {
        let sorted = physiqueEntries.sorted { $0.date < $1.date }
        guard let index = sorted.firstIndex(where: { $0.id == entry.id }), index > 0,
              let currentBMI = bmi(for: entry),
              let previousBMI = bmi(for: sorted[index - 1]) else { return nil }
        return currentBMI - previousBMI
    }

    // MARK: - Derived state & actions: Diet

    public var macroTargets: MacroTargets { MacroCalculator.targets(for: dietProfile) }

    /// Just today's entries, by calendar day — `mealLog` itself keeps full
    /// history (useful for a future trends view), but "today's log" and
    /// the calorie/macro totals must not silently accumulate every day
    /// logged since install.
    public var todaysMealLog: [MealEntry] {
        mealLog.filter { calendar.isDate($0.date, inSameDayAs: now()) }
    }

    public var dietSummary: DietSummary {
        let targets = macroTargets
        let totals = todaysMealLog.reduce((cals: 0, p: 0, c: 0, f: 0)) { acc, m in
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
        dietProfile = dietProfile.clamped()
        dietScreen = .dashboard
        let profile = dietProfile
        Task { try? await repository.saveDietProfile(profile) }
    }

    public func editDietProfile() { dietScreen = .setup }

    public func setDietHistoryMode(_ mode: DietHistoryMode) { dietHistoryMode = mode }

    public var canAddCustomMeal: Bool {
        !newMealName.trimmingCharacters(in: .whitespaces).isEmpty && (Int(newMealCalories) ?? 0) > 0
    }

    /// Today's log in the order each meal was actually logged — bodybuilders
    /// eating 6+ small meals a day don't fit neatly into
    /// breakfast/lunch/dinner/snack, so meals are just timestamped and
    /// listed chronologically instead of forced into fixed categories.
    public var todaysMealTimeline: [MealEntry] {
        todaysMealLog.sorted { $0.date < $1.date }
    }

    /// Logs a saved-food-library item immediately, timestamped now.
    public func logSavedFood(_ food: SavedFood) {
        mealLog.append(MealEntry(date: now(), name: food.name, calories: food.calories, proteinGrams: food.proteinGrams, carbGrams: food.carbGrams, fatGrams: food.fatGrams))
        persistMealLog()
    }

    public func deleteSavedFood(_ id: String) {
        savedFoods.removeAll { $0.id == id }
        persistSavedFoods()
    }

    /// Populates the log-meal draft from an existing entry and marks it as
    /// the one being edited — the form (and `saveMeal()`) reuse the same
    /// draft fields for both adding and editing rather than introducing
    /// parallel state.
    public func beginEditingMeal(_ id: String) {
        guard let entry = mealLog.first(where: { $0.id == id }) else { return }
        editingMealID = id
        newMealName = entry.name
        newMealCalories = String(entry.calories)
        newMealProtein = String(entry.proteinGrams)
        newMealCarb = String(entry.carbGrams)
        newMealFat = String(entry.fatGrams)
    }

    public func cancelEditingMeal() { clearMealDraft() }

    /// Updates the entry in place if `editingMealID` is set, otherwise
    /// appends a new one and — since this is a hand-typed *new* food, not a
    /// re-log from the library — also saves it to `savedFoods` so it's
    /// reusable next time (deduped by case-insensitive name match, so
    /// re-typing something already in the library doesn't create a copy).
    public func saveMeal() {
        guard canAddCustomMeal else { return }
        let name = newMealName.trimmingCharacters(in: .whitespaces)
        let calories = Int(newMealCalories) ?? 0
        let protein = Int(newMealProtein) ?? 0
        let carb = Int(newMealCarb) ?? 0
        let fat = Int(newMealFat) ?? 0

        if let editingMealID, let index = mealLog.firstIndex(where: { $0.id == editingMealID }) {
            let existing = mealLog[index]
            mealLog[index] = MealEntry(id: existing.id, date: existing.date, name: name, calories: calories, proteinGrams: protein, carbGrams: carb, fatGrams: fat)
        } else {
            mealLog.append(MealEntry(date: now(), name: name, calories: calories, proteinGrams: protein, carbGrams: carb, fatGrams: fat))
            addToLibraryIfNew(name: name, calories: calories, proteinGrams: protein, carbGrams: carb, fatGrams: fat)
        }

        clearMealDraft()
        persistMealLog()
    }

    private func addToLibraryIfNew(name: String, calories: Int, proteinGrams: Int, carbGrams: Int, fatGrams: Int) {
        let alreadyExists = savedFoods.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        guard !alreadyExists else { return }
        savedFoods.append(SavedFood(name: name, calories: calories, proteinGrams: proteinGrams, carbGrams: carbGrams, fatGrams: fatGrams))
        persistSavedFoods()
    }

    private func clearMealDraft() {
        newMealName = ""
        newMealCalories = ""
        newMealProtein = ""
        newMealCarb = ""
        newMealFat = ""
        editingMealID = nil
    }

    public func removeMeal(_ id: String) {
        mealLog.removeAll { $0.id == id }
        if editingMealID == id { clearMealDraft() }
        persistMealLog()
    }

    private func persistMealLog() {
        let snapshot = mealLog
        Task { try? await repository.saveMealLog(snapshot) }
    }

    private func persistSavedFoods() {
        let snapshot = savedFoods
        Task { try? await repository.saveSavedFoods(snapshot) }
    }

    // MARK: - Diet history / trends

    /// Full `mealLog` history (not just today) grouped by calendar day for
    /// the trailing `days` days, oldest→newest, zero-filled for days with
    /// nothing logged so a chart has a continuous x-axis.
    public func mealHistory(days: Int) -> [DailyMacroSummary] {
        let today = calendar.startOfDay(for: now())
        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let entries = mealLog.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let totals = entries.reduce((cals: 0, p: 0, c: 0, f: 0)) { acc, m in
                (acc.cals + m.calories, acc.p + m.proteinGrams, acc.c + m.carbGrams, acc.f + m.fatGrams)
            }
            return DailyMacroSummary(date: day, calories: totals.cals, proteinGrams: totals.p, carbGrams: totals.c, fatGrams: totals.f)
        }
    }

    /// Averages over the same trailing window, skipping unlogged (zero)
    /// days so a few good days aren't dragged down by days the app wasn't
    /// opened.
    public func mealHistoryAverages(days: Int) -> MealHistoryAverages {
        let loggedDays = mealHistory(days: days).filter { $0.calories > 0 }
        let count = max(1, loggedDays.count)
        let totals = loggedDays.reduce((cals: 0, p: 0, c: 0, f: 0)) { acc, d in
            (acc.cals + d.calories, acc.p + d.proteinGrams, acc.c + d.carbGrams, acc.f + d.fatGrams)
        }
        return MealHistoryAverages(
            averageCalories: totals.cals / count,
            averageProteinGrams: totals.p / count,
            averageCarbGrams: totals.c / count,
            averageFatGrams: totals.f / count,
            daysLogged: loggedDays.count
        )
    }
}
