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

// MARK: - WorkoutLibrary completeness

for category in LiftCategory.allCases {
    for freq in TrainingFrequency.allCases {
        let variants = WorkoutLibrary.variants(for: category, frequency: freq)
        check(variants.count == 3, "\(category.rawValue) \(freq.rawValue)-day has 3 variants")
        for v in variants {
            check(v.days.count == freq.days, "\(v.name) has \(freq.days) days")
        }
    }
}

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

// MARK: - AppViewModel behavior

let vm = await AppViewModel(repository: MockWorkoutRepository())
await vm.load()
await MainActor.run {
    vm.openCategory(.lift(.bodybuilding))
    vm.selectFrequency(.fourDay)
    vm.selectVariant(0)
    vm.startProgram()
    check(vm.plan.count == 1, "startProgram adds one plan entry")
    check(vm.workoutScreen == .today, "startProgram navigates to today screen")
    check(vm.isLifting, "selected category reports as lifting")

    vm.selectWeekday(0)
    if let day = vm.selectedTrainingDay {
        for i in 0..<day.items.count { vm.toggleExercise(i) }
        check(vm.isSessionComplete, "checking every exercise completes the session")
    } else {
        check(false, "Monday should have a training day for a 4-day Bodybuilding program")
    }

    check(vm.readiness?.score == 82, "readiness loads from repository")
    check(vm.physiqueEntries.count == 3, "physique entries seed from repository")
}

print("\nAll smoke checks passed.")
