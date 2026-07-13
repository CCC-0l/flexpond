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

let vm = await AppViewModel(repository: LocalWorkoutRepository(defaults: UserDefaults(suiteName: "flexpond.smoke")!))
await vm.load()
await MainActor.run {
    vm.openCategory(.program(.bodybuilding))
    vm.selectFrequency(.fourDay)
    vm.selectVariant(0)
    vm.startProgram()
    check(vm.plan.count == 1, "startProgram adds one plan entry")
    check(vm.workoutScreen == .today, "startProgram navigates to today screen")

    check(vm.readiness?.score == 82, "readiness loads from repository")
    check(vm.physiqueEntries.count == 6, "6 seeded physique entries with real photos")
    check(vm.homeReadinessScore == 82, "home readiness falls back to static 82 pre-Oura-connect")
    check(vm.homeReadinessLabel == "Primed to train", "home readiness label falls back pre-connect")

    let ids = vm.physiqueEntries.map { $0.id }
    vm.toggleCompareEntry(ids[0])
    vm.toggleCompareEntry(ids[1])
    check(vm.selectedEntryIDs == [ids[0], ids[1]], "compare selects first two toggled entries")
    vm.toggleCompareEntry(ids[2])
    check(vm.selectedEntryIDs == [ids[1], ids[2]], "compare evicts oldest selection FIFO once 2 are picked")
}

print("\nAll smoke checks passed.")
