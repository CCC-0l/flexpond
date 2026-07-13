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

    // MARK: - MacroCalculator

    @Test func macroCalculatorMifflinMaleMaintain() {
        // 30yo male, 5'10", 180lb, moderate activity, maintain.
        let profile = DietProfile(age: 30, gender: .male, heightFeet: 5, heightInches: 10, weightPounds: 180, activity: .moderate, goal: .maintain, formula: .mifflin, bodyFatPercent: 20)
        let targets = MacroCalculator.targets(for: profile)
        // weightKg = 81.6466, heightCm = 177.8
        // bmr = 10*81.6466 + 6.25*177.8 - 5*30 + 5 = 816.466 + 1111.25 - 150 + 5 = 1782.716
        // tdee = 1782.716 * 1.55 = 2763.21 -> targetCalories = 2763
        #expect(targets.targetCalories == 2763)
        #expect(targets.proteinGrams == 207) // round(2763*0.30/4)
        #expect(targets.carbGrams == 276)    // round(2763*0.40/4)
        #expect(targets.fatGrams == 92)      // round(2763*0.30/9)
    }

    @Test func macroCalculatorFloorsAt1200Calories() {
        var profile = DietProfile(age: 90, gender: .female, heightFeet: 4, heightInches: 10, weightPounds: 90, activity: .sedentary, goal: .extremeLoss, formula: .mifflin, bodyFatPercent: 20)
        profile.age = DietProfile.clampedAge(profile.age)
        let targets = MacroCalculator.targets(for: profile)
        #expect(targets.targetCalories == 1200)
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

    @Test func readinessStatusThresholds() {
        #expect(ReadinessStatus(score: 90) == .optimal)
        #expect(ReadinessStatus(score: 85) == .optimal)
        #expect(ReadinessStatus(score: 84) == .balanced)
        #expect(ReadinessStatus(score: 70) == .balanced)
        #expect(ReadinessStatus(score: 69) == .payAttention)
    }
}
