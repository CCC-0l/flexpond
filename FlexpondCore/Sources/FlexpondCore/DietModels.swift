import Foundation

public enum DietGender: String, Codable, Sendable {
    case male, female
}

public enum DietScreen: Sendable {
    case setup, dashboard
}

/// Which of "Today" or "Trends" the Diet dashboard is showing — mirrors
/// `PhysiqueViewMode`'s Timeline/Compare pattern.
public enum DietHistoryMode: Sendable {
    case today, trends
}

public enum BMRFormula: String, Codable, Sendable {
    case mifflin, katch
}

public enum ActivityLevel: String, CaseIterable, Codable, Identifiable, Sendable {
    case sedentary, light, moderate, active, veryActive = "veryactive", extraActive = "extraactive"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        case .extraActive: return "Extra Active"
        }
    }

    public var detail: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "Exercise 1–3 times/week"
        case .moderate: return "Exercise 4–5 times/week"
        case .active: return "Daily exercise or intense 3–4x/week"
        case .veryActive: return "Intense exercise 6–7 times/week"
        case .extraActive: return "Very intense daily, or physical job"
        }
    }

    /// TDEE multiplier applied to BMR.
    public var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        case .extraActive: return 2.0
        }
    }
}

public enum DietGoal: String, CaseIterable, Codable, Identifiable, Sendable {
    case maintain, mildLoss = "mildloss", loss, extremeLoss = "extremeloss"
    case mildGain = "mildgain", gain, extremeGain = "extremegain"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .maintain: return "Maintain weight"
        case .mildLoss: return "Mild weight loss"
        case .loss: return "Weight loss"
        case .extremeLoss: return "Extreme weight loss"
        case .mildGain: return "Mild weight gain"
        case .gain: return "Weight gain"
        case .extremeGain: return "Extreme weight gain"
        }
    }

    public var detail: String {
        switch self {
        case .maintain: return "Stay at current weight"
        case .mildLoss: return "0.5 lb per week"
        case .loss: return "1 lb per week"
        case .extremeLoss: return "2 lb per week"
        case .mildGain: return "0.5 lb per week"
        case .gain: return "1 lb per week"
        case .extremeGain: return "2 lb per week"
        }
    }

    /// Daily calorie adjustment from TDEE.
    public var calorieAdjustment: Int {
        switch self {
        case .maintain: return 0
        case .mildLoss: return -250
        case .loss: return -500
        case .extremeLoss: return -1000
        case .mildGain: return 250
        case .gain: return 500
        case .extremeGain: return 1000
        }
    }
}

public struct DietProfile: Codable, Sendable, Equatable {
    public var age: Int
    public var gender: DietGender
    public var heightFeet: Int
    public var heightInches: Int
    public var weightPounds: Int
    public var activity: ActivityLevel
    public var goal: DietGoal
    public var formula: BMRFormula
    public var bodyFatPercent: Int

    public init(
        age: Int = 30,
        gender: DietGender = .male,
        heightFeet: Int = 5,
        heightInches: Int = 10,
        weightPounds: Int = 180,
        activity: ActivityLevel = .moderate,
        goal: DietGoal = .maintain,
        formula: BMRFormula = .mifflin,
        bodyFatPercent: Int = 20
    ) {
        self.age = age
        self.gender = gender
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.weightPounds = weightPounds
        self.activity = activity
        self.goal = goal
        self.formula = formula
        self.bodyFatPercent = bodyFatPercent
    }

    // Mirrors the mockup's `Math.max(lo, Math.min(hi, v))` clamps exactly.
    // Its `|| fallback` suffix is unreachable there too (the max() floor is
    // always > 0), so there's nothing to replicate beyond the plain clamp.
    //
    // Deliberately NOT applied on every keystroke in the view layer — a
    // text field bound through a live-clamping Binding snaps to the floor
    // the instant a single low digit is typed (e.g. typing "2" toward "25"
    // instantly becomes "10"), which then re-displays and overwrites
    // whatever the user was mid-typing, making multi-digit entry
    // impossible. Fields bind directly to these properties instead, and
    // `clamped()` is applied only at the boundaries where the values are
    // actually used: `MacroCalculator.targets(for:)` and
    // `AppViewModel.calculateDiet()`.
    public static func clampedAge(_ value: Int) -> Int { value.clamped(10...100) }
    public static func clampedHeightFeet(_ value: Int) -> Int { value.clamped(3...7) }
    public static func clampedHeightInches(_ value: Int) -> Int { value.clamped(0...11) }
    public static func clampedWeight(_ value: Int) -> Int { value.clamped(50...600) }
    public static func clampedBodyFat(_ value: Int) -> Int { value.clamped(3...60) }

    /// A copy with every field clamped into its valid range — applied at
    /// calculation/persistence boundaries, not while the user is typing.
    public func clamped() -> DietProfile {
        var copy = self
        copy.age = Self.clampedAge(age)
        copy.heightFeet = Self.clampedHeightFeet(heightFeet)
        copy.heightInches = Self.clampedHeightInches(heightInches)
        copy.weightPounds = Self.clampedWeight(weightPounds)
        copy.bodyFatPercent = Self.clampedBodyFat(bodyFatPercent)
        return copy
    }
}

private extension Int {
    func clamped(_ range: ClosedRange<Int>) -> Int {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

public struct MacroTargets: Sendable, Equatable {
    public let targetCalories: Int
    public let proteinGrams: Int
    public let carbGrams: Int
    public let fatGrams: Int
}

/// BMR/TDEE/calorie-target math is transcribed exactly from the mockup's
/// `renderVals()` diet section (`dc.html` lines 1503-1516) and verified
/// against a third-party TDEE calculator (calculator.net) byte-for-byte.
///
/// The macro *split*, however, deliberately diverges from the mockup's
/// fixed 30% protein / 40% carb / 30% fat of total calories. A %-of-calories
/// split is the wrong tool for an app built around structured lifting
/// programs: it undershoots protein on a cut (exactly when preserving
/// muscle matters most) and swings protein arbitrarily high or low on a
/// bulk, since it's tracking total calories rather than the thing that
/// actually determines protein need — bodyweight. Protein here is instead
/// anchored at 1g per lb of bodyweight (squarely inside the ISSN's
/// recommended 0.7–1g/lb range for resistance-trained individuals,
/// regardless of goal), fat holds a 25% floor of total calories for
/// hormone health, and carbs fill whatever calories remain.
public enum MacroCalculator {
    public static func targets(for rawProfile: DietProfile) -> MacroTargets {
        // Clamped here (not while the user is typing — see DietProfile's
        // clamped() doc comment) so a mid-edit or garbage value can never
        // produce a nonsensical calorie/macro target.
        let profile = rawProfile.clamped()
        let weightKg = Double(profile.weightPounds) * 0.453592
        let heightCm = Double((profile.heightFeet * 12) + profile.heightInches) * 2.54

        let bmr: Double
        switch profile.formula {
        case .katch:
            let leanKg = weightKg * (1 - Double(profile.bodyFatPercent) / 100)
            bmr = 370 + 21.6 * leanKg
        case .mifflin:
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(profile.age)) + (profile.gender == .male ? 5 : -161)
        }

        let tdee = bmr * profile.activity.multiplier
        let targetCalories = max(1200, Int((tdee + Double(profile.goal.calorieAdjustment)).rounded()))

        let proteinGrams = profile.weightPounds
        let proteinCalories = Double(proteinGrams) * 4
        let fatCalories = Double(targetCalories) * 0.25
        let fatGrams = Int((fatCalories / 9).rounded())
        let carbCalories = max(0, Double(targetCalories) - proteinCalories - fatCalories)
        let carbGrams = Int((carbCalories / 4).rounded())

        return MacroTargets(targetCalories: targetCalories, proteinGrams: proteinGrams, carbGrams: carbGrams, fatGrams: fatGrams)
    }
}

public struct MealEntry: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let date: Date
    public let name: String
    public let calories: Int
    public let proteinGrams: Int
    public let carbGrams: Int
    public let fatGrams: Int

    public init(id: String = UUID().uuidString, date: Date, name: String, calories: Int, proteinGrams: Int, carbGrams: Int, fatGrams: Int) {
        self.id = id
        self.date = date
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbGrams = carbGrams
        self.fatGrams = fatGrams
    }
}

/// A food the user has saved once and can re-log without retyping macros —
/// the "personal food library." Seeded with 4 starter items (the same ones
/// the old fixed `QuickMeal` presets used); grows as the user logs new
/// custom meals (see `AppViewModel.saveMeal()`).
public struct SavedFood: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let calories: Int
    public let proteinGrams: Int
    public let carbGrams: Int
    public let fatGrams: Int

    public init(id: String = UUID().uuidString, name: String, calories: Int, proteinGrams: Int, carbGrams: Int, fatGrams: Int) {
        self.id = id
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbGrams = carbGrams
        self.fatGrams = fatGrams
    }

    public static let starterLibrary: [SavedFood] = [
        SavedFood(name: "Chicken & Rice Bowl", calories: 520, proteinGrams: 45, carbGrams: 55, fatGrams: 12),
        SavedFood(name: "Protein Shake", calories: 180, proteinGrams: 30, carbGrams: 8, fatGrams: 3),
        SavedFood(name: "Greek Yogurt & Berries", calories: 220, proteinGrams: 20, carbGrams: 24, fatGrams: 5),
        SavedFood(name: "Eggs & Toast", calories: 380, proteinGrams: 24, carbGrams: 30, fatGrams: 18),
    ]
}

public struct DailyMacroSummary: Identifiable, Sendable {
    public var id: Date { date }
    public let date: Date
    public let calories: Int
    public let proteinGrams: Int
    public let carbGrams: Int
    public let fatGrams: Int
}

public struct MealHistoryAverages: Sendable {
    public let averageCalories: Int
    public let averageProteinGrams: Int
    public let averageCarbGrams: Int
    public let averageFatGrams: Int
    public let daysLogged: Int
}
