// Standalone smoke test, runnable via `swift run Smoke`.
//
// `swift test` needs XCTest/Swift Testing runtime bits (lib_TestingInterop.dylib
// etc.) that only ship with full Xcode, not the bare Command Line Tools this
// machine has installed. This executable exercises the same assertions using
// plain `precondition`, so the port can be verified without Xcode.
import Foundation
import FlexpondCore

func check(_ condition: Bool, _ message: String, file: StaticString = #file, line: UInt = #line) {
    guard condition else {
        fatalError("FAILED: \(message)", file: file, line: line)
    }
    print("ok - \(message)")
}

// MARK: - ExerciseEntry parsing

do {
    let e = ExerciseEntry(raw: "Bench Press 4x8-10")
    check(e.name == "Bench Press", "parses name before sets/reps")
    check(e.setsReps == "4 × 8-10", "parses sets/reps token")
}
do {
    let e = ExerciseEntry(raw: "Walking Lunges 3x12/leg")
    check(e.name == "Walking Lunges", "parses name with slash rep scheme")
    check(e.setsReps == "3 × 12/leg", "parses slash rep scheme")
}
do {
    let e = ExerciseEntry(raw: "Squat variation — work up to a heavy 1-3RM")
    check(e.name == "Squat variation — work up to a heavy 1-3RM", "leaves free-form text untouched")
    check(e.setsReps == "", "no sets/reps token found")
}
do {
    let e = ExerciseEntry(raw: "Speed Squats 8x2 @ 55-60%")
    check(e.name == "Speed Squats", "parses name before percentage note")
    check(e.setsReps == "8 × 2 @ 55-60%", "keeps trailing percentage in sets/reps")
}

// MARK: - WorkoutLibrary completeness (5 categories now: 3 lifting + HIT + MC)

for category in ProgramCategory.allCases {
    for freq in TrainingFrequency.allCases {
        let variants = WorkoutLibrary.variants(for: category, frequency: freq)
        check(variants.count == 3, "\(category.rawValue) \(freq.rawValue)-day has 3 variants")
        for v in variants {
            check(v.days.count == freq.days, "\(v.name) has \(freq.days) days")
        }
    }
}
check(ProgramCategory.allCases.count == 5, "5 program categories (BB/PL/TO/HIT/MC)")

// MARK: - Schedule mapping

check(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 0) == 0, "4-day Mon trains")
check(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 1) == 1, "4-day Tue trains")
check(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 2) == nil, "4-day Wed rests")
check(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 3) == 2, "4-day Thu trains")
check(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 4) == 3, "4-day Fri trains")
check(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 5) == nil, "4-day Sat rests")
check(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 6) == nil, "4-day Sun rests")
for wd in 0...5 {
    check(WorkoutSchedule.trainingDayIndex(frequency: .sixDay, weekday: wd) == wd, "6-day weekday \(wd) trains")
}
check(WorkoutSchedule.trainingDayIndex(frequency: .sixDay, weekday: 6) == nil, "6-day Sun rests")

do {
    var comps = DateComponents()
    comps.year = 2026; comps.month = 7; comps.day = 6 // Monday, Jul 6 2026
    let calendar = Calendar(identifier: .gregorian)
    let monday = calendar.date(from: comps)!
    check(WorkoutSchedule.mondayIndexedWeekday(from: monday, calendar: calendar) == 0, "Monday maps to index 0")
    let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
    check(WorkoutSchedule.mondayIndexedWeekday(from: sunday, calendar: calendar) == 6, "Sunday maps to index 6")
}

// MARK: - MacroCalculator

do {
    let profile = DietProfile(age: 30, gender: .male, heightFeet: 5, heightInches: 10, weightPounds: 180, activity: .moderate, goal: .maintain, formula: .mifflin, bodyFatPercent: 20)
    let targets = MacroCalculator.targets(for: profile)
    check(targets.targetCalories == 2763, "Mifflin male maintain -> 2763 cal")
    check(targets.proteinGrams == 180, "protein grams = 1g per lb bodyweight (180lb)")
    check(targets.fatGrams == 77, "fat grams from 25% of target cal / 9")
    check(targets.carbGrams == 338, "carb grams fill the remaining calories")
}
do {
    let profile = DietProfile(age: 90, gender: .female, heightFeet: 4, heightInches: 10, weightPounds: 90, activity: .sedentary, goal: .extremeLoss, formula: .mifflin, bodyFatPercent: 20)
    let targets = MacroCalculator.targets(for: profile)
    check(targets.targetCalories == 1200, "macro calculator floors at 1200 cal")
}
do {
    // Very high bodyweight at the 1200-cal floor: protein alone can exceed
    // the whole calorie target, so carbs must clamp at 0, not go negative.
    let profile = DietProfile(age: 90, gender: .female, heightFeet: 4, heightInches: 10, weightPounds: 600, activity: .sedentary, goal: .extremeLoss, formula: .mifflin, bodyFatPercent: 20)
    let targets = MacroCalculator.targets(for: profile)
    check(targets.proteinGrams == 600, "protein still tracks bodyweight even at the calorie floor")
    check(targets.carbGrams == 0, "carbs clamp at 0 rather than going negative")
}
check(DietProfile.clampedAge(5) == 10, "age clamps below range to the floor")
check(DietProfile.clampedAge(150) == 100, "age clamps above range")
check(DietProfile.clampedHeightInches(15) == 11, "height inches clamp to 11")
check(DietProfile.clampedHeightInches(-3) == 0, "height inches clamp to 0")

do {
    let wild = DietProfile(age: 2, gender: .male, heightFeet: 1, heightInches: 99, weightPounds: 3, activity: .moderate, goal: .maintain, formula: .katch, bodyFatPercent: 0)
    let clamped = wild.clamped()
    check(clamped.age == 10 && clamped.heightFeet == 3 && clamped.heightInches == 11 && clamped.weightPounds == 50 && clamped.bodyFatPercent == 3, "DietProfile.clamped() clamps every field at once")
}
do {
    // A field mid-edit (or just garbage) shouldn't reach the math
    // unclamped — targets(for:) must match calling it pre-clamped.
    let wild = DietProfile(age: 1, gender: .male, heightFeet: 0, heightInches: 0, weightPounds: 1, activity: .moderate, goal: .maintain, formula: .mifflin, bodyFatPercent: 20)
    let wildTargets = MacroCalculator.targets(for: wild)
    let clampedTargets = MacroCalculator.targets(for: wild.clamped())
    check(wildTargets.targetCalories == clampedTargets.targetCalories, "MacroCalculator.targets clamps out-of-range calories input defensively")
    check(wildTargets.proteinGrams == clampedTargets.proteinGrams, "MacroCalculator.targets clamps out-of-range protein input defensively")
}

// MARK: - Oura

do {
    let json = """
    {
      "data": [
        {
          "day": "2026-07-09",
          "score": 79,
          "contributors": {
            "activity_balance": 91,
            "body_temperature": 88,
            "hrv_balance": 62,
            "previous_day_activity": 95,
            "previous_night": 74,
            "recovery_index": 80,
            "resting_heart_rate": 89,
            "sleep_balance": 58
          }
        }
      ],
      "next_token": null
    }
    """.data(using: .utf8)!
    let decoded = try! JSONDecoder().decode(OuraReadinessResponse.self, from: json)
    let day = decoded.data.last!
    check(day.score == 79, "decodes Oura fixture score")
    check(day.contributors.hrvBalance == 62, "decodes hrv_balance via snake_case CodingKeys")
    let focus = OuraService().focusContributors(for: day)
    check(focus.map { $0.label } == ["Sleep Balance", "HRV Balance"], "focus picks the 2 lowest-scoring contributors")
    check(ReadinessStatus(score: 90) == .optimal, "score >=85 is Optimal")
    check(ReadinessStatus(score: 70) == .balanced, "score >=70 is Balanced")
    check(ReadinessStatus(score: 50) == .payAttention, "score <70 is Pay attention")
}

do {
    // Real Oura accounts commonly have null contributors (e.g. no HRV
    // baseline yet) — this must not throw a DecodingError.
    let json = """
    {
      "data": [
        {
          "day": "2026-07-13",
          "score": 71,
          "contributors": {
            "activity_balance": null,
            "body_temperature": 88,
            "hrv_balance": null,
            "previous_day_activity": 95,
            "previous_night": 74,
            "recovery_index": 80,
            "resting_heart_rate": 89,
            "sleep_balance": null
          }
        }
      ],
      "next_token": null
    }
    """.data(using: .utf8)!
    let decoded = try! JSONDecoder().decode(OuraReadinessResponse.self, from: json)
    let day = decoded.data.last!
    check(day.contributors.hrvBalance == nil, "null contributor decodes as nil, not a thrown error")
    check(day.contributors.all.count == 5, "all filters out the 3 null contributors")
    let focus = OuraService().focusContributors(for: day)
    check(focus.count == 2, "focus still finds 2 lowest among the 5 present contributors")
}

// MARK: - AppViewModel behavior

// Unlike the Testing-framework tests (which use unique #function-based
// suite names), these hardcoded suite names would otherwise persist to
// disk across separate `swift run` invocations and silently pollute the
// next run's starting state (e.g. a leftover plan entry from last time
// throwing off a "count == 1" assertion this run). Clear them first so
// every run starts from a clean slate.
for suiteName in ["flexpond.smoke", "flexpond.smoke.today", "flexpond.smoke.mealdate", "flexpond.smoke.mealtype", "flexpond.smoke.mealedit", "flexpond.smoke.mealgroups", "flexpond.smoke.mealhistory"] {
    UserDefaults().removePersistentDomain(forName: suiteName)
}

let vm = await AppViewModel(repository: LocalWorkoutRepository(defaults: UserDefaults(suiteName: "flexpond.smoke")!))
await vm.load()
await MainActor.run {
    vm.openCategory(.program(.bodybuilding))
    vm.selectFrequency(.fourDay)
    vm.selectVariant(0)
    vm.startProgram()
    check(vm.plan.count == 1, "startProgram adds one plan entry")
    check(vm.workoutScreen == .today, "startProgram navigates to today screen")

    vm.openCategory(.program(.powerlifting))
    vm.selectFrequency(.fourDay)
    vm.startProgram()
    check(vm.plan.count == 1, "starting a 2nd lifting program replaces the 1st, doesn't stack")

    vm.openCategory(.program(.moderateIntensityCardio))
    vm.selectFrequency(.fourDay)
    vm.startProgram()
    check(vm.plan.count == 2, "a cardio program lives alongside the lifting one")

    vm.dietProfile.age = 2 // simulates a mid-edit/garbage value reaching submit
    vm.calculateDiet()
    check(vm.dietProfile.age == 10, "calculateDiet clamps the stored profile")
    check(vm.dietScreen == .dashboard, "calculateDiet still navigates to the dashboard")

    check(vm.readiness?.score == 82, "readiness loads from repository")
    check(vm.physiqueEntries.count == 6, "6 seeded physique entries with real photos")
    check(vm.homeReadinessScore == 82, "home readiness falls back to static 82 pre-Oura-connect")
    check(vm.homeReadinessLabel == "Primed to train", "home readiness label falls back pre-connect")

    // Physique stats
    let day1 = vm.physiqueEntries.first { $0.id == "day1" }!
    let wk6 = vm.physiqueEntries.first { $0.id == "wk6" }!
    check(abs((vm.bmi(for: day1) ?? 0) - 25.54) < 0.05, "bmi(for:) uses DietProfile height (default 5'10\")")
    check(vm.weightDelta(for: day1) == nil, "first chronological entry has no delta to compare against")
    check(vm.weightDelta(for: wk6) == 2, "weightDelta vs chronologically previous entry (180 - 178)")
    check((vm.bmiDelta(for: wk6) ?? 0) > 0, "gained weight -> bmiDelta positive")

    vm.setPhotoIdentifier("day1-front", for: .front, entryID: "day1")
    check(vm.physiqueEntries.first { $0.id == "day1" }?.photoFileName(for: .front) == "day1-front", "setPhotoIdentifier updates the given pose")
    check(vm.physiqueEntries.first { $0.id == "day1" }?.photoFileName(for: .back) == "phys-day1-back", "setPhotoIdentifier leaves other poses untouched")

    vm.updateEntryWeight("day1", weightPounds: 175)
    check(vm.physiqueEntries.first { $0.id == "day1" }?.weightPounds == 175, "updateEntryWeight edits in place")

    let countBeforeAdd = vm.physiqueEntries.count
    vm.newEntryWeight = "195"
    vm.addPhysiqueEntry()
    check(vm.physiqueEntries.count == countBeforeAdd + 1, "addPhysiqueEntry appends one entry")
    check(vm.physiqueEntries.last?.weightPounds == 195, "addPhysiqueEntry uses the draft weight")
    check(vm.newEntryWeight == "", "addPhysiqueEntry clears the draft after use")

    let ids = vm.physiqueEntries.map { $0.id }
    vm.toggleCompareEntry(ids[0])
    vm.toggleCompareEntry(ids[1])
    check(vm.selectedEntryIDs == [ids[0], ids[1]], "compare selects first two toggled entries")
    vm.toggleCompareEntry(ids[2])
    check(vm.selectedEntryIDs == [ids[1], ids[2]], "compare evicts oldest selection FIFO once 2 are picked")

    vm.deletePhysiqueEntry(ids[1])
    check(vm.physiqueEntries.contains { $0.id == ids[1] } == false, "deletePhysiqueEntry removes the entry")
    check(vm.selectedEntryIDs.contains(ids[1]) == false, "deleting a compare-selected entry clears its selection")
}

check(PhysiqueStats.bmi(weightPounds: 180, heightFeet: 5, heightInches: 10) != nil, "PhysiqueStats.bmi computes with valid height")
check(PhysiqueStats.bmi(weightPounds: 180, heightFeet: 0, heightInches: 0) == nil, "PhysiqueStats.bmi is nil without a height")

do {
    var comps = DateComponents()
    comps.year = 2026; comps.month = 7; comps.day = 6 // Monday, Jul 6 2026
    let calendar = Calendar(identifier: .gregorian)
    let monday = calendar.date(from: comps)!
    let vm2 = await AppViewModel(repository: LocalWorkoutRepository(defaults: UserDefaults(suiteName: "flexpond.smoke.today")!), calendar: calendar, now: { monday })
    await vm2.load()
    await MainActor.run {
        vm2.openCategory(.program(.bodybuilding))
        vm2.selectFrequency(.fourDay)
        vm2.selectVariant(0) // Upper/Lower Split — Monday = "Upper A"
        vm2.startProgram()

        vm2.openCategory(.program(.moderateIntensityCardio))
        vm2.selectFrequency(.fourDay)
        vm2.selectVariant(0) // Outdoor Run Progression — Monday = "Zone 2 Base Run"
        vm2.startProgram()

        check(vm2.todaysLiftingSchedule?.sessionLabel == "Upper A", "today's lifting schedule shows Monday's session")
        check(vm2.todaysLiftingSchedule?.isRestDay == false, "Monday is a training day for a 4-day BB split")
        check(vm2.todaysLiftingSchedule?.exercises.isEmpty == false, "today's lifting schedule includes exercises")
        check(vm2.todaysCardioSchedule?.sessionLabel == "Zone 2 Base Run", "today's cardio schedule shows Monday's session")
        check(vm2.todaysCardioSchedule?.category == .moderateIntensityCardio, "cardio schedule item carries the right category")
        check(vm2.walkPlanItem == nil, "no walk goal set yet")
    }
}

do {
    var currentDate = Date()
    let vm3 = await AppViewModel(repository: LocalWorkoutRepository(defaults: UserDefaults(suiteName: "flexpond.smoke.mealdate")!), now: { currentDate })
    await vm3.load()
    await MainActor.run {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        vm3.logSavedFood(SavedFood.starterLibrary[0])

        currentDate = Date()
        vm3.logSavedFood(SavedFood.starterLibrary[1])

        check(vm3.mealLog.count == 2, "full meal history keeps entries from every day")
        check(vm3.todaysMealLog.count == 1, "todaysMealLog filters out yesterday's entry")
        check(vm3.todaysMealLog.first?.name == SavedFood.starterLibrary[1].name, "todaysMealLog keeps only today's entry")
        check(vm3.dietSummary.consumedCalories == SavedFood.starterLibrary[1].calories, "dietSummary totals only count today, not full history")
    }
}

// MARK: - MealType / food library / meal editing / history

do {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    func hourDate(_ hour: Int) -> Date {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 7; comps.day = 6; comps.hour = hour
        comps.timeZone = calendar.timeZone
        return calendar.date(from: comps)!
    }
    check(MealType.current(at: hourDate(0), calendar: calendar) == .breakfast, "midnight defaults to breakfast")
    check(MealType.current(at: hourDate(10), calendar: calendar) == .breakfast, "10am defaults to breakfast")
    check(MealType.current(at: hourDate(11), calendar: calendar) == .lunch, "11am defaults to lunch")
    check(MealType.current(at: hourDate(14), calendar: calendar) == .lunch, "2pm defaults to lunch")
    check(MealType.current(at: hourDate(15), calendar: calendar) == .dinner, "3pm defaults to dinner")
    check(MealType.current(at: hourDate(20), calendar: calendar) == .dinner, "8pm defaults to dinner")
    check(MealType.current(at: hourDate(21), calendar: calendar) == .snack, "9pm defaults to snack")
    check(MealType.current(at: hourDate(23), calendar: calendar) == .snack, "11pm defaults to snack")
}

do {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    var comps = DateComponents()
    comps.year = 2026; comps.month = 7; comps.day = 6; comps.hour = 8
    comps.timeZone = calendar.timeZone
    let morning = calendar.date(from: comps)!
    let vm4 = await AppViewModel(repository: LocalWorkoutRepository(defaults: UserDefaults(suiteName: "flexpond.smoke.mealtype")!), calendar: calendar, now: { morning })
    await vm4.load()
    await MainActor.run {
        vm4.logSavedFood(SavedFood.starterLibrary[0])
        check(vm4.mealLog.last?.mealType == .breakfast, "logSavedFood defaults to the time-of-day meal type")
        vm4.logSavedFood(SavedFood.starterLibrary[1], mealType: .dinner)
        check(vm4.mealLog.last?.mealType == .dinner, "logSavedFood honors an explicit meal type")
    }
}

do {
    let vm5 = await AppViewModel(repository: LocalWorkoutRepository(defaults: UserDefaults(suiteName: "flexpond.smoke.mealedit")!))
    await vm5.load()
    await MainActor.run {
        let startingCount = vm5.savedFoods.count
        vm5.newMealName = "Test Custom Meal"
        vm5.newMealCalories = "300"
        vm5.newMealProtein = "20"
        vm5.newMealCarb = "30"
        vm5.newMealFat = "10"
        vm5.saveMeal()
        check(vm5.savedFoods.count == startingCount + 1, "saveMeal adds a new custom food to the library")
        check(vm5.mealLog.count == 1, "saveMeal logs the entry")
        check(vm5.newMealName == "", "saveMeal clears the draft")

        vm5.newMealName = "test custom meal"
        vm5.newMealCalories = "300"
        vm5.newMealProtein = "20"
        vm5.newMealCarb = "30"
        vm5.newMealFat = "10"
        vm5.saveMeal()
        check(vm5.savedFoods.count == startingCount + 1, "re-logging the same name (case-insensitive) doesn't duplicate the library entry")
        check(vm5.mealLog.count == 2, "but a 2nd log entry was still created")

        vm5.logSavedFood(SavedFood.starterLibrary[0], mealType: .breakfast)
        let entryID = vm5.mealLog.last!.id
        let libraryCountBefore = vm5.savedFoods.count
        vm5.beginEditingMeal(entryID)
        check(vm5.newMealName == SavedFood.starterLibrary[0].name, "beginEditingMeal populates the draft")
        check(vm5.editingMealID == entryID, "beginEditingMeal marks the entry as being edited")
        vm5.newMealCalories = "999"
        vm5.newMealType = .dinner
        vm5.saveMeal()
        check(vm5.mealLog.count == 3, "saveMeal updates the edited entry in place, doesn't append")
        check(vm5.mealLog.last?.calories == 999, "edited entry reflects the new value")
        check(vm5.mealLog.last?.mealType == .dinner, "edited entry reflects the new meal type")
        check(vm5.editingMealID == nil, "saveMeal clears editingMealID")
        check(vm5.savedFoods.count == libraryCountBefore, "editing an existing entry doesn't touch the library")

        vm5.beginEditingMeal(vm5.mealLog.last!.id)
        vm5.newMealCalories = "1"
        vm5.cancelEditingMeal()
        check(vm5.editingMealID == nil, "cancelEditingMeal clears editingMealID")
        check(vm5.mealLog.last?.calories == 999, "cancelEditingMeal discards the in-progress edit")
    }
}

do {
    let vm6 = await AppViewModel(repository: LocalWorkoutRepository(defaults: UserDefaults(suiteName: "flexpond.smoke.mealgroups")!))
    await vm6.load()
    await MainActor.run {
        vm6.logSavedFood(SavedFood.starterLibrary[0], mealType: .breakfast)
        vm6.logSavedFood(SavedFood.starterLibrary[1], mealType: .breakfast)
        vm6.logSavedFood(SavedFood.starterLibrary[2], mealType: .dinner)

        let summaries = vm6.todaysMealTypeSummaries
        check(summaries.map { $0.type } == [.breakfast, .lunch, .dinner, .snack], "todaysMealTypeSummaries always returns all 4 types in order")
        check(summaries[0].entries.count == 2, "breakfast group has 2 entries")
        check(summaries[0].calories == SavedFood.starterLibrary[0].calories + SavedFood.starterLibrary[1].calories, "breakfast subtotal sums correctly")
        check(summaries[1].entries.isEmpty, "lunch group is empty but still present")
        check(summaries[2].entries.count == 1, "dinner group has 1 entry")
        check(summaries[3].entries.isEmpty, "snack group is empty but still present")
    }
}

do {
    var currentDate = Date()
    let calendar = Calendar.current
    let vm7 = await AppViewModel(repository: LocalWorkoutRepository(defaults: UserDefaults(suiteName: "flexpond.smoke.mealhistory")!), now: { currentDate })
    await vm7.load()
    await MainActor.run {
        currentDate = calendar.date(byAdding: .day, value: -2, to: Date())!
        vm7.logSavedFood(SavedFood.starterLibrary[0])

        currentDate = Date()
        vm7.logSavedFood(SavedFood.starterLibrary[1])

        let history = vm7.mealHistory(days: 3)
        check(history.count == 3, "mealHistory returns exactly the requested number of days")
        check(history[0].calories == SavedFood.starterLibrary[0].calories, "oldest day has the 2-days-ago entry")
        check(history[1].calories == 0, "the empty gap day is zero-filled")
        check(history[2].calories == SavedFood.starterLibrary[1].calories, "newest day has today's entry")
        check(history.map { $0.date } == history.map { $0.date }.sorted(), "mealHistory is oldest-to-newest")

        let averages = vm7.mealHistoryAverages(days: 3)
        check(averages.daysLogged == 2, "mealHistoryAverages counts only logged days")
        check(averages.averageCalories == (SavedFood.starterLibrary[0].calories + SavedFood.starterLibrary[1].calories) / 2, "average skips the zero-filled gap day")
    }
}

print("\nAll smoke checks passed.")
