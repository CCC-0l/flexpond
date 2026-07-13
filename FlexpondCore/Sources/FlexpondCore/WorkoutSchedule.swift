import Foundation

/// Maps a Mon(0)...Sun(6) weekday index to a training-day index within a
/// variant's `days` array, or `nil` for a rest day. Ported from the mockup's
/// `SCHED` table.
public enum WorkoutSchedule {
    public static let weekdayAbbreviations = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    public static let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    private static let fourDay = [0, 1, -1, 2, 3, -1, -1]
    private static let sixDay = [0, 1, 2, 3, 4, 5, -1]

    public static func dayIndices(for frequency: TrainingFrequency) -> [Int] {
        frequency == .fourDay ? fourDay : sixDay
    }

    /// - Parameter weekday: 0 = Monday ... 6 = Sunday.
    public static func trainingDayIndex(frequency: TrainingFrequency, weekday: Int) -> Int? {
        let sched = dayIndices(for: frequency)
        guard weekday >= 0, weekday < sched.count else { return nil }
        let idx = sched[weekday]
        return idx >= 0 ? idx : nil
    }

    /// Today as a Mon=0...Sun=6 index, from a `Calendar`'s `weekday` (Sun=1...Sat=7).
    public static func mondayIndexedWeekday(from date: Date, calendar: Calendar = .current) -> Int {
        let sunday1 = calendar.component(.weekday, from: date) // 1 = Sunday ... 7 = Saturday
        return (sunday1 + 5) % 7 // Monday -> 0
    }
}
