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
        for category in LiftCategory.allCases {
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
        let vm = AppViewModel(repository: MockWorkoutRepository())
        await vm.load()
        vm.openCategory(.lift(.bodybuilding))
        vm.selectFrequency(.fourDay)
        vm.selectVariant(0)
        vm.startProgram()
        #expect(vm.plan.count == 1)
        #expect(vm.workoutScreen == .today)
        #expect(vm.isLifting)
    }

    @Test @MainActor func completingAllExercisesMarksSessionComplete() async {
        let vm = AppViewModel(repository: MockWorkoutRepository())
        await vm.load()
        vm.openCategory(.lift(.bodybuilding))
        vm.selectFrequency(.fourDay)
        vm.startProgram()
        // Jump to a known training weekday (Monday = 0) so there is a session to complete.
        vm.selectWeekday(0)
        let day = vm.selectedTrainingDay
        #expect(day != nil)
        for i in 0..<(day?.items.count ?? 0) {
            vm.toggleExercise(i)
        }
        #expect(vm.isSessionComplete)
    }

    @Test @MainActor func readinessLoadsFromRepository() async {
        let vm = AppViewModel(repository: MockWorkoutRepository())
        await vm.load()
        #expect(vm.readiness?.score == 82)
        #expect(vm.physiqueEntries.count == 3)
    }
}
