import Testing
import Foundation
@testable import FlexpondCore

struct FlexpondCoreTests {

    @Test func exerciseEntryParsesSetsReps() {
        let e = ExerciseEntry(raw: "Bench Press 4x8-10")
        #expect(e.name == "Bench Press")
        #expect(e.setsReps == "4 × 8-10")
    }

    @Test func exerciseEntryParsesSlashRepsScheme() {
        let e = ExerciseEntry(raw: "Walking Lunges 3x12/leg")
        #expect(e.name == "Walking Lunges")
        #expect(e.setsReps == "3 × 12/leg")
    }

    @Test func exerciseEntryWithoutSetsReps() {
        let e = ExerciseEntry(raw: "Squat variation — work up to a heavy 1-3RM")
        #expect(e.name == "Squat variation — work up to a heavy 1-3RM")
        #expect(e.setsReps == "")
    }

    @Test func exerciseEntryWithTrailingPercentage() {
        let e = ExerciseEntry(raw: "Speed Squats 8x2 @ 55-60%")
        #expect(e.name == "Speed Squats")
        #expect(e.setsReps == "8 × 2 @ 55-60%")
    }

    @Test func workoutLibraryHasAllCategoriesAndFrequencies() {
        for category in ProgramCategory.allCases {
            for freq in TrainingFrequency.allCases {
                let variants = WorkoutLibrary.variants(for: category, frequency: freq)
                #expect(variants.count == 3)
                for v in variants {
                    #expect(v.days.count == freq.days)
                }
            }
        }
    }

    @Test func scheduleFourDayRestDays() {
        // Mon, Tue, Thu, Fri train; Wed, Sat, Sun rest.
        #expect(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 0) == 0)
        #expect(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 1) == 1)
        #expect(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 2) == nil)
        #expect(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 3) == 2)
        #expect(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 4) == 3)
        #expect(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 5) == nil)
        #expect(WorkoutSchedule.trainingDayIndex(frequency: .fourDay, weekday: 6) == nil)
    }

    @Test func scheduleSixDayOnlySundayRests() {
        for wd in 0...5 {
            #expect(WorkoutSchedule.trainingDayIndex(frequency: .sixDay, weekday: wd) == wd)
        }
        #expect(WorkoutSchedule.trainingDayIndex(frequency: .sixDay, weekday: 6) == nil)
    }

    @Test func mondayIndexedWeekdayMapping() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 7; comps.day = 6 // Monday, Jul 6 2026
        let calendar = Calendar(identifier: .gregorian)
        let monday = calendar.date(from: comps)!
        #expect(WorkoutSchedule.mondayIndexedWeekday(from: monday, calendar: calendar) == 0)

        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
        #expect(WorkoutSchedule.mondayIndexedWeekday(from: sunday, calendar: calendar) == 6)
    }

    @Test @MainActor func startProgramAddsToPlanAndNavigatesToToday() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.openCategory(.program(.bodybuilding))
        vm.selectFrequency(.fourDay)
        vm.selectVariant(0)
        vm.startProgram()
        #expect(vm.plan.count == 1)
        #expect(vm.workoutScreen == .today)
    }

    @Test @MainActor func startProgramReplacesExistingProgramInSameSection() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.openCategory(.program(.bodybuilding))
        vm.selectFrequency(.fourDay)
        vm.startProgram()
        #expect(vm.plan.count == 1)

        // Starting a second lifting program should replace the first, not stack.
        vm.openCategory(.program(.powerlifting))
        vm.selectFrequency(.fourDay)
        vm.startProgram()
        #expect(vm.plan.count == 1)
        if case .program(_, let category, _, _) = vm.plan[0] {
            #expect(category == .powerlifting)
        } else {
            Issue.record("expected a program plan item")
        }

        // A cardio program lives alongside the lifting one — different section.
        vm.openCategory(.program(.moderateIntensityCardio))
        vm.selectFrequency(.fourDay)
        vm.startProgram()
        #expect(vm.plan.count == 2)
    }

    @Test @MainActor func todaysScheduleReflectsLiftingAndCardioIndependently() async {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 7; comps.day = 6 // Monday, Jul 6 2026
        let calendar = Calendar(identifier: .gregorian)
        let monday = calendar.date(from: comps)!

        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!), calendar: calendar, now: { monday })
        await vm.load()

        vm.openCategory(.program(.bodybuilding))
        vm.selectFrequency(.fourDay)
        vm.selectVariant(0) // Upper/Lower Split — Monday = "Upper A"
        vm.startProgram()

        vm.openCategory(.program(.moderateIntensityCardio))
        vm.selectFrequency(.fourDay)
        vm.selectVariant(0) // Outdoor Run Progression — Monday = "Zone 2 Base Run"
        vm.startProgram()

        #expect(vm.todaysLiftingSchedule?.sessionLabel == "Upper A")
        #expect(vm.todaysLiftingSchedule?.isRestDay == false)
        #expect(vm.todaysLiftingSchedule?.dayName == "Monday")
        #expect(vm.todaysLiftingSchedule?.exercises.isEmpty == false)

        #expect(vm.todaysCardioSchedule?.sessionLabel == "Zone 2 Base Run")
        #expect(vm.todaysCardioSchedule?.category == .moderateIntensityCardio)

        #expect(vm.walkPlanItem == nil)
    }

    @Test @MainActor func readinessAndPhysiqueLoadFromRepository() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        #expect(vm.readiness?.score == 82)
        #expect(vm.physiqueEntries.count == 6)
        #expect(vm.homeReadinessScore == 82)
        #expect(vm.homeReadinessLabel == "Primed to train")
    }

    @Test @MainActor func physiqueCompareTogglesUpToTwoEntriesFIFO() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        let ids = vm.physiqueEntries.map(\.id)
        vm.toggleCompareEntry(ids[0])
        vm.toggleCompareEntry(ids[1])
        #expect(vm.selectedEntryIDs == [ids[0], ids[1]])
        vm.toggleCompareEntry(ids[2])
        #expect(vm.selectedEntryIDs == [ids[1], ids[2]])
        vm.toggleCompareEntry(ids[2])
        #expect(vm.selectedEntryIDs == [ids[1]])
    }

    // MARK: - Physique stats

    @Test func physiqueStatsBMIKnownValue() {
        let bmi = PhysiqueStats.bmi(weightPounds: 180, heightFeet: 5, heightInches: 10)
        #expect(bmi != nil)
        #expect(abs(bmi! - 25.83) < 0.01)
    }

    @Test func physiqueStatsBMINilWithoutHeight() {
        #expect(PhysiqueStats.bmi(weightPounds: 180, heightFeet: 0, heightInches: 0) == nil)
    }

    @Test @MainActor func physiqueBMIUsesDietProfileHeight() async throws {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        let day1 = try #require(vm.physiqueEntries.first { $0.id == "day1" })
        let bmi = try #require(vm.bmi(for: day1))
        #expect(abs(bmi - 25.54) < 0.05)
    }

    @Test @MainActor func physiqueDeltasComputeVsChronologicallyPreviousEntry() async throws {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        let day1 = try #require(vm.physiqueEntries.first { $0.id == "day1" })
        let wk6 = try #require(vm.physiqueEntries.first { $0.id == "wk6" })

        #expect(vm.weightDelta(for: day1) == nil) // first entry, nothing to compare against
        #expect(vm.weightDelta(for: wk6) == 2)     // 180 - 178
        #expect((vm.bmiDelta(for: wk6) ?? 0) > 0)   // gained weight -> BMI went up
    }

    @Test @MainActor func setPhotoIdentifierUpdatesOnlyTheGivenPose() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.setPhotoIdentifier("day1-front", for: .front, entryID: "day1")
        let day1 = vm.physiqueEntries.first { $0.id == "day1" }
        #expect(day1?.photoFileName(for: .front) == "day1-front")
        #expect(day1?.photoFileName(for: .back) == "phys-day1-back") // untouched
    }

    @Test @MainActor func updateEntryWeightEditsInPlace() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.updateEntryWeight("day1", weightPounds: 175)
        #expect(vm.physiqueEntries.first { $0.id == "day1" }?.weightPounds == 175)
    }

    @Test @MainActor func deletePhysiqueEntryRemovesItAndClearsCompareSelection() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.toggleCompareEntry("day1")
        #expect(vm.selectedEntryIDs == ["day1"])
        vm.deletePhysiqueEntry("day1")
        #expect(vm.physiqueEntries.contains { $0.id == "day1" } == false)
        #expect(vm.selectedEntryIDs.isEmpty)
    }

    @Test @MainActor func addPhysiqueEntryUsesDraftWeightThenClearsIt() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        let countBefore = vm.physiqueEntries.count
        vm.newEntryWeight = "195"
        vm.addPhysiqueEntry()
        #expect(vm.physiqueEntries.count == countBefore + 1)
        #expect(vm.physiqueEntries.last?.weightPounds == 195)
        #expect(vm.newEntryWeight == "")
    }

    @Test @MainActor func addPhysiqueEntryGivesEveryEntryAUniqueID() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.addPhysiqueEntry()
        let firstID = vm.physiqueEntries.last!.id
        vm.addPhysiqueEntry()
        #expect(vm.physiqueEntries.last!.id != firstID)
    }

    @Test @MainActor func todaysMealLogFiltersOutOlderDaysButKeepsFullHistory() async {
        var currentDate = Date()
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!), now: { currentDate })
        await vm.load()

        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        vm.logSavedFood(SavedFood.starterLibrary[0])

        currentDate = Date()
        vm.logSavedFood(SavedFood.starterLibrary[1])

        #expect(vm.mealLog.count == 2)
        #expect(vm.todaysMealLog.count == 1)
        #expect(vm.todaysMealLog.first?.name == SavedFood.starterLibrary[1].name)
        #expect(vm.dietSummary.consumedCalories == SavedFood.starterLibrary[1].calories)
    }

    // MARK: - Chronological meal timeline / food library / meal editing / history

    @Test @MainActor func todaysMealTimelineSortsByTimestampNotInsertionOrder() async {
        var currentDate = Date()
        let calendar = Calendar.current
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!), calendar: calendar, now: { currentDate })
        await vm.load()

        let base = calendar.startOfDay(for: currentDate)
        // Logged out of order (3pm, 8am, noon) — there's no meal-type bucket
        // to lean on, so the timeline must sort by actual timestamp.
        currentDate = calendar.date(byAdding: .hour, value: 15, to: base)!
        vm.logSavedFood(SavedFood.starterLibrary[0])
        currentDate = calendar.date(byAdding: .hour, value: 8, to: base)!
        vm.logSavedFood(SavedFood.starterLibrary[1])
        currentDate = calendar.date(byAdding: .hour, value: 12, to: base)!
        vm.logSavedFood(SavedFood.starterLibrary[2])

        let timeline = vm.todaysMealTimeline
        #expect(timeline.map(\.name) == [SavedFood.starterLibrary[1].name, SavedFood.starterLibrary[2].name, SavedFood.starterLibrary[0].name])
    }

    @Test @MainActor func anyNumberOfMealsCanBeLoggedWithNoCategoryLimit() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()

        // A 6-small-meals-a-day split shouldn't run out of room in a fixed category.
        for _ in 0..<6 { vm.logSavedFood(SavedFood.starterLibrary[0]) }
        #expect(vm.todaysMealTimeline.count == 6)
    }

    @Test @MainActor func saveMealAddsNewCustomFoodToLibraryAndDedupesByName() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        let startingCount = vm.savedFoods.count

        vm.newMealName = "Test Custom Meal"
        vm.newMealCalories = "300"
        vm.newMealProtein = "20"
        vm.newMealCarb = "30"
        vm.newMealFat = "10"
        vm.saveMeal()

        #expect(vm.savedFoods.count == startingCount + 1)
        #expect(vm.mealLog.count == 1)
        #expect(vm.newMealName == "") // draft cleared after save

        // Re-logging the same name (case-insensitive) shouldn't duplicate the library entry.
        vm.newMealName = "test custom meal"
        vm.newMealCalories = "300"
        vm.newMealProtein = "20"
        vm.newMealCarb = "30"
        vm.newMealFat = "10"
        vm.saveMeal()

        #expect(vm.savedFoods.count == startingCount + 1) // no new library entry
        #expect(vm.mealLog.count == 2) // but a 2nd log entry was created
    }

    @Test @MainActor func beginEditingMealPopulatesDraftAndSaveUpdatesInPlace() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.logSavedFood(SavedFood.starterLibrary[0])
        let entryID = vm.mealLog[0].id
        let libraryCountBefore = vm.savedFoods.count

        vm.beginEditingMeal(entryID)
        #expect(vm.newMealName == SavedFood.starterLibrary[0].name)
        #expect(vm.editingMealID == entryID)

        vm.newMealCalories = "999"
        vm.saveMeal()

        #expect(vm.mealLog.count == 1) // updated in place, not appended
        #expect(vm.mealLog[0].calories == 999)
        #expect(vm.editingMealID == nil)
        #expect(vm.savedFoods.count == libraryCountBefore) // editing an existing entry doesn't touch the library
    }

    @Test @MainActor func cancelEditingMealClearsDraftWithoutSaving() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.logSavedFood(SavedFood.starterLibrary[0])
        vm.beginEditingMeal(vm.mealLog[0].id)
        vm.newMealCalories = "999"
        vm.cancelEditingMeal()

        #expect(vm.editingMealID == nil)
        #expect(vm.newMealName == "")
        #expect(vm.mealLog[0].calories == SavedFood.starterLibrary[0].calories) // unchanged
    }

    @Test @MainActor func mealHistoryZeroFillsGapDaysAndAveragesSkipThem() async {
        var currentDate = Date()
        let calendar = Calendar.current
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!), now: { currentDate })
        await vm.load()

        currentDate = calendar.date(byAdding: .day, value: -2, to: Date())!
        vm.logSavedFood(SavedFood.starterLibrary[0]) // 520 cal, 2 days ago

        currentDate = Date()
        vm.logSavedFood(SavedFood.starterLibrary[1]) // 180 cal, today — yesterday left empty

        let history = vm.mealHistory(days: 3)
        #expect(history.count == 3)
        #expect(history[0].calories == SavedFood.starterLibrary[0].calories)
        #expect(history[1].calories == 0)
        #expect(history[2].calories == SavedFood.starterLibrary[1].calories)
        #expect(history.map(\.date) == history.map(\.date).sorted())

        let averages = vm.mealHistoryAverages(days: 3)
        #expect(averages.daysLogged == 2)
        #expect(averages.averageCalories == (SavedFood.starterLibrary[0].calories + SavedFood.starterLibrary[1].calories) / 2)
    }

    // MARK: - MacroCalculator

    @Test func macroCalculatorMifflinMaleMaintain() {
        // 30yo male, 5'10", 180lb, moderate activity, maintain.
        let profile = DietProfile(age: 30, gender: .male, heightFeet: 5, heightInches: 10, weightPounds: 180, activity: .moderate, goal: .maintain, formula: .mifflin, bodyFatPercent: 20)
        let targets = MacroCalculator.targets(for: profile)
        // weightKg = 81.6466, heightCm = 177.8
        // bmr = 10*81.6466 + 6.25*177.8 - 5*30 + 5 = 816.466 + 1111.25 - 150 + 5 = 1782.716
        // tdee = 1782.716 * 1.55 = 2763.21 -> targetCalories = 2763
        // Verified against calculator.net's Mifflin-St Jeor result independently.
        #expect(targets.targetCalories == 2763)
        // Protein anchored to bodyweight (1g/lb), not % of calories — see
        // MacroCalculator's doc comment for why.
        #expect(targets.proteinGrams == 180)
        #expect(targets.fatGrams == 77)   // round(2763*0.25/9)
        #expect(targets.carbGrams == 338) // remaining calories after protein+fat, /4
    }

    @Test func macroCalculatorFloorsAt1200Calories() {
        var profile = DietProfile(age: 90, gender: .female, heightFeet: 4, heightInches: 10, weightPounds: 90, activity: .sedentary, goal: .extremeLoss, formula: .mifflin, bodyFatPercent: 20)
        profile.age = DietProfile.clampedAge(profile.age)
        let targets = MacroCalculator.targets(for: profile)
        #expect(targets.targetCalories == 1200)
    }

    @Test func macroCalculatorClampsCarbsAtZeroWhenProteinAloneExceedsCalories() {
        // A very high bodyweight at the 1200-calorie floor: protein alone
        // (weightPounds * 4 cal) can exceed the whole calorie target, so
        // carbs must clamp at 0 rather than go negative.
        let profile = DietProfile(age: 90, gender: .female, heightFeet: 4, heightInches: 10, weightPounds: 600, activity: .sedentary, goal: .extremeLoss, formula: .mifflin, bodyFatPercent: 20)
        let targets = MacroCalculator.targets(for: profile)
        #expect(targets.targetCalories == 1200)
        #expect(targets.proteinGrams == 600)
        #expect(targets.carbGrams == 0)
    }

    @Test func macroCalculatorKatchUsesBodyFat() {
        let profile = DietProfile(age: 30, gender: .male, heightFeet: 5, heightInches: 10, weightPounds: 180, activity: .moderate, goal: .maintain, formula: .katch, bodyFatPercent: 20)
        let targets = MacroCalculator.targets(for: profile)
        // leanKg = 81.6466 * 0.8 = 65.317, bmr = 370 + 21.6*65.317 = 1780.85
        // tdee = 1780.85 * 1.55 = 2760.3 -> 2760
        #expect(targets.targetCalories == 2760)
    }

    @Test func dietProfileClampsAgeHeightWeightBodyFat() {
        #expect(DietProfile.clampedAge(5) == 10)
        #expect(DietProfile.clampedAge(150) == 100)
        #expect(DietProfile.clampedHeightFeet(2) == 3)
        #expect(DietProfile.clampedHeightFeet(9) == 7)
        #expect(DietProfile.clampedHeightInches(15) == 11)
        #expect(DietProfile.clampedHeightInches(-3) == 0)
        #expect(DietProfile.clampedWeight(10) == 50)
        #expect(DietProfile.clampedWeight(9000) == 600)
        #expect(DietProfile.clampedBodyFat(1) == 3)
        #expect(DietProfile.clampedBodyFat(90) == 60)
    }

    @Test func dietProfileClampedReturnsFullyClampedCopy() {
        let wild = DietProfile(age: 2, gender: .male, heightFeet: 1, heightInches: 99, weightPounds: 3, activity: .moderate, goal: .maintain, formula: .katch, bodyFatPercent: 0)
        let clamped = wild.clamped()
        #expect(clamped.age == 10)
        #expect(clamped.heightFeet == 3)
        #expect(clamped.heightInches == 11)
        #expect(clamped.weightPounds == 50)
        #expect(clamped.bodyFatPercent == 3)
    }

    @Test func macroCalculatorClampsOutOfRangeInputsRatherThanProducingNonsenseTargets() {
        // A field mid-edit (or just garbage) shouldn't be allowed to reach
        // the math unclamped — targets(for:) must behave identically to
        // calling it with the pre-clamped profile.
        let wild = DietProfile(age: 1, gender: .male, heightFeet: 0, heightInches: 0, weightPounds: 1, activity: .moderate, goal: .maintain, formula: .mifflin, bodyFatPercent: 20)
        let wildTargets = MacroCalculator.targets(for: wild)
        let clampedTargets = MacroCalculator.targets(for: wild.clamped())
        #expect(wildTargets.targetCalories == clampedTargets.targetCalories)
        #expect(wildTargets.proteinGrams == clampedTargets.proteinGrams)
    }

    @Test @MainActor func calculateDietClampsAndPersistsTheStoredProfile() async {
        let vm = AppViewModel(repository: LocalWorkoutRepository(defaults: .init(suiteName: #function)!))
        await vm.load()
        vm.dietProfile.age = 2 // simulates a mid-edit/garbage value reaching submit
        vm.calculateDiet()
        #expect(vm.dietProfile.age == 10)
        #expect(vm.dietScreen == .dashboard)
    }

    // MARK: - Oura

    @Test func ouraReadinessResponseDecodesFixtureJSON() throws {
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

        let decoded = try JSONDecoder().decode(OuraReadinessResponse.self, from: json)
        let day = try #require(decoded.data.last)
        #expect(day.score == 79)
        #expect(day.contributors.hrvBalance == 62)
        #expect(day.contributors.activityBalance == 91)

        let service = OuraService()
        let focus = service.focusContributors(for: day)
        #expect(focus.count == 2)
        #expect(focus.map(\.label) == ["Sleep Balance", "HRV Balance"])
        #expect(focus.map(\.score) == [58, 62])
    }

    @Test func ouraReadinessDecodesWithNullContributors() throws {
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

        let decoded = try JSONDecoder().decode(OuraReadinessResponse.self, from: json)
        let day = try #require(decoded.data.last)
        #expect(day.contributors.hrvBalance == nil)
        #expect(day.contributors.all.count == 5)
        #expect(!day.contributors.all.contains { $0.label == "HRV Balance" })

        let service = OuraService()
        let focus = service.focusContributors(for: day)
        #expect(focus.count == 2)
    }

    @Test func ouraSnapshotPreservesNilScoreInsteadOfCollapsingToZero() {
        // A ring/account without enough history yet can have no computed
        // overall score. Collapsing that to 0 before persisting would make
        // "no score data" reload as a literal score of zero after the next
        // cold launch.
        let noScoreDay = OuraReadinessDay(
            day: "2026-07-20",
            score: nil,
            contributors: OuraContributors(activityBalance: nil, bodyTemperature: nil, hrvBalance: nil, previousDayActivity: nil, previousNight: nil, recoveryIndex: nil, restingHeartRate: nil, sleepBalance: nil)
        )
        let snapshot = OuraSnapshot(day: noScoreDay, syncedAt: Date())
        #expect(snapshot.score == nil)
    }

    @Test func readinessStatusThresholds() {
        #expect(ReadinessStatus(score: 90) == .optimal)
        #expect(ReadinessStatus(score: 85) == .optimal)
        #expect(ReadinessStatus(score: 84) == .balanced)
        #expect(ReadinessStatus(score: 70) == .balanced)
        #expect(ReadinessStatus(score: 69) == .payAttention)
    }
}
