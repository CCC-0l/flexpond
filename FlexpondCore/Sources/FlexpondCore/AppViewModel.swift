import Foundation
import Combine

// MARK: - View-friendly derived data

public struct WeekDayCell: Identifiable, Sendable {
    public let id: Int // Monday = 0 ... Sunday = 6
    public let abbreviation: String
    public let isToday: Bool
    public let isSelected: Bool
    public let isRestDay: Bool
    public let isDone: Bool
}

public struct PlanRow: Identifiable, Sendable {
    public let id: String
    public let badge: String
    public let title: String
    public let subtitle: String
    public let isLift: Bool
    public let progress: Double // 0...1, only meaningful when isLift
    public let weekLabel: String
    public let isDoneToday: Bool
}

public struct VariantOption: Identifiable, Sendable {
    public let id: Int
    public let variant: ProgramVariant
    public let isSelected: Bool
    public let tags: [String]
}

// MARK: - AppViewModel

@MainActor
public final class AppViewModel: ObservableObject {
    private let repository: WorkoutRepository
    private let calendar: Calendar
    private let now: () -> Date

    // Tab / navigation
    @Published public var selectedTab: AppTab = .home
    @Published public var workoutScreen: WorkoutScreen = .browse
    @Published public var selectedCategory: WorkoutCategory?
    @Published public var frequency: TrainingFrequency = .fourDay
    @Published public var variantIndex: Int = 0
    @Published public var selectedWeekday: Int?

    // Plan / progress
    @Published public private(set) var plan: [PlanItem] = []
    @Published public var completedExercises: [String: Set<Int>] = [:]

    // Walk goal
    @Published public var walkGoal: Int = 10_000
    @Published public var walkGoalSaved: Bool = false

    // Readiness
    @Published public private(set) var readiness: ReadinessData?

    // Physique
    @Published public private(set) var physiqueEntries: [PhysiqueEntry] = []
    @Published public var physiqueViewMode: PhysiqueViewMode = .timeline
    @Published public var compareIndexA: Int = 0
    @Published public var compareIndexB: Int = 2

    public init(repository: WorkoutRepository = MockWorkoutRepository(), calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
        Task { await load() }
    }

    public func load() async {
        async let planTask = repository.fetchPlan()
        async let readinessTask = repository.fetchReadiness()
        async let physiqueTask = repository.fetchPhysiqueEntries()
        if let plan = try? await planTask { self.plan = plan }
        if let readiness = try? await readinessTask { self.readiness = readiness }
        if let entries = try? await physiqueTask { self.physiqueEntries = entries }
    }

    // MARK: - Derived state

    public var todayWeekday: Int { WorkoutSchedule.mondayIndexedWeekday(from: now(), calendar: calendar) }
    public var effectiveWeekday: Int { selectedWeekday ?? todayWeekday }

    public var isLifting: Bool { selectedCategory?.isLifting ?? false }

    public var activeVariants: [ProgramVariant] {
        guard case .lift(let category) = selectedCategory else { return [] }
        return WorkoutLibrary.variants(for: category, frequency: frequency)
    }

    public var activeVariant: ProgramVariant? {
        let variants = activeVariants
        guard variantIndex < variants.count else { return variants.first }
        return variants[variantIndex]
    }

    private var contextKey: String {
        guard case .lift(let category) = selectedCategory else { return "" }
        return "\(category.rawValue)-\(frequency.rawValue)-\(variantIndex)"
    }

    private func dayKey(_ dayIndex: Int) -> String { "\(contextKey)#\(dayIndex)" }

    public var selectedTrainingDayIndex: Int? {
        WorkoutSchedule.trainingDayIndex(frequency: frequency, weekday: effectiveWeekday)
    }

    public var selectedTrainingDay: TrainingDay? {
        guard let idx = selectedTrainingDayIndex, let variant = activeVariant, idx < variant.days.count else { return nil }
        return variant.days[idx]
    }

    public var isRestDay: Bool { selectedTrainingDay == nil }

    public var weekStrip: [WeekDayCell] {
        let sched = WorkoutSchedule.dayIndices(for: frequency)
        return (0..<7).map { i in
            let dayIdx = sched[i]
            let isRest = dayIdx < 0 || (activeVariant.map { dayIdx >= $0.days.count } ?? true)
            let done = !isRest && (completedExercises[dayKey(dayIdx)]?.count ?? 0) >= (activeVariant?.days[dayIdx].items.count ?? 0) && (activeVariant?.days[dayIdx].items.isEmpty == false)
            return WeekDayCell(
                id: i,
                abbreviation: WorkoutSchedule.weekdayAbbreviations[i],
                isToday: i == todayWeekday,
                isSelected: i == effectiveWeekday,
                isRestDay: isRest,
                isDone: done
            )
        }
    }

    public var todayCompletedIndices: Set<Int> {
        guard let idx = selectedTrainingDayIndex else { return [] }
        return completedExercises[dayKey(idx)] ?? []
    }

    public var isSessionComplete: Bool {
        guard let day = selectedTrainingDay, !day.items.isEmpty else { return false }
        return todayCompletedIndices.count >= day.items.count
    }

    public var variantOptions: [VariantOption] {
        var meta: LiftCategory?
        if case .lift(let c) = selectedCategory { meta = c }
        let tags = meta.map { [frequency.rawValue + " days/wk", $0.repRange, $0.restRange + " rest"] } ?? []
        return activeVariants.enumerated().map { i, v in
            VariantOption(id: i, variant: v, isSelected: i == variantIndex, tags: tags)
        }
    }

    public var planRows: [PlanRow] {
        plan.map { item in
            switch item {
            case .walk(let id, let goal):
                return PlanRow(id: id, badge: "WK", title: "Walk", subtitle: "\(goal.formatted()) steps / day", isLift: false, progress: 0, weekLabel: "", isDoneToday: false)
            case .lift(let id, let category, let freq, let variantIdx):
                let variants = WorkoutLibrary.variants(for: category, frequency: freq)
                let variant = variantIdx < variants.count ? variants[variantIdx] : variants.first
                let sched = WorkoutSchedule.dayIndices(for: freq)
                let scheduledDayCount = sched.filter { $0 >= 0 }.count
                let key = "\(category.rawValue)-\(freq.rawValue)-\(variantIdx)"
                let doneDayCount = (0..<7).filter { wd in
                    let di = sched[wd]
                    guard di >= 0, let variant, di < variant.days.count, !variant.days[di].items.isEmpty else { return false }
                    return (completedExercises["\(key)#\(di)"]?.count ?? 0) >= variant.days[di].items.count
                }.count
                let todayDi = sched[todayWeekday]
                let restToday = todayDi < 0 || variant.map { todayDi >= $0.days.count } ?? true
                let todayLabel = variant != nil && !restToday ? "Today · \(variant!.days[todayDi].label)" : (restToday ? "Rest day today" : "")
                return PlanRow(
                    id: id,
                    badge: category.badge,
                    title: category.rawValue,
                    subtitle: "\(variant?.name ?? "") · \(freq.rawValue)-day",
                    isLift: true,
                    progress: scheduledDayCount == 0 ? 0 : Double(doneDayCount) / Double(scheduledDayCount),
                    weekLabel: "\(doneDayCount)/\(scheduledDayCount) this wk",
                    isDoneToday: !todayLabel.isEmpty && restToday == false && (completedExercises["\(key)#\(todayDi)"]?.count ?? 0) >= (variant?.days[todayDi].items.count ?? Int.max)
                )
            }
        }
    }

    // MARK: - Actions

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
    }

    public func selectVariant(_ index: Int) { variantIndex = index }

    public func startProgram() {
        guard case .lift(let category) = selectedCategory else { return }
        let id = PlanItem.liftID(category: category, frequency: frequency, variantIndex: variantIndex)
        if !plan.contains(where: { $0.id == id }) {
            plan.append(.lift(id: id, category: category, frequency: frequency, variantIndex: variantIndex))
            persistPlan()
        }
        selectedWeekday = nil
        workoutScreen = .today
    }

    public func openPlanRow(_ row: PlanRow) {
        guard let item = plan.first(where: { $0.id == row.id }) else { return }
        switch item {
        case .lift(_, let category, let freq, let variantIdx):
            selectedCategory = .lift(category)
            frequency = freq
            variantIndex = variantIdx
            selectedWeekday = nil
            selectedTab = .workout
            workoutScreen = .today
        case .walk:
            selectedCategory = .cardio(.walk)
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

    public func toggleExercise(_ index: Int) {
        guard let dayIdx = selectedTrainingDayIndex else { return }
        let key = dayKey(dayIdx)
        var set = completedExercises[key] ?? []
        if set.contains(index) { set.remove(index) } else { set.insert(index) }
        completedExercises[key] = set
    }

    public func completeSession() {
        guard let dayIdx = selectedTrainingDayIndex, let day = selectedTrainingDay else { return }
        completedExercises[dayKey(dayIdx)] = Set(0..<day.items.count)
    }

    public func resetWeek() {
        let prefix = contextKey + "#"
        completedExercises = completedExercises.filter { !$0.key.hasPrefix(prefix) }
    }

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
    }

    public func setPhysiqueViewMode(_ mode: PhysiqueViewMode) { physiqueViewMode = mode }
    public func selectCompareA(_ i: Int) { compareIndexA = min(i, max(physiqueEntries.count - 1, 0)) }
    public func selectCompareB(_ i: Int) { compareIndexB = min(i, max(physiqueEntries.count - 1, 0)) }

    public func addPhysiqueEntry() {
        let entry = PhysiqueEntry(id: "e\(physiqueEntries.count + 1)", label: "New set", date: now())
        physiqueEntries.append(entry)
        Task { try? await repository.addPhysiqueEntry(entry) }
    }

    private func persistPlan() {
        let snapshot = plan
        Task { try? await repository.savePlan(snapshot) }
    }
}
