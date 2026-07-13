import Foundation

/// Static workout program catalog, ported 1:1 from the Claude Design mockup's
/// embedded `LIFTING` data. Swap `WorkoutRepository`'s implementation to serve
/// this from a real backend without touching call sites.
public enum WorkoutLibrary {
    public static let programs: [LiftCategory: [TrainingFrequency: [ProgramVariant]]] = [
        .bodybuilding: [
            .fourDay: [
                ProgramVariant(
                    name: "Upper / Lower Split",
                    description: "Classic strength-hypertrophy split hitting each muscle group twice per week.",
                    days: [
                        TrainingDay(label: "Upper A", items: ["Bench Press 4x8-10", "Bent-Over Row 4x8-10", "Overhead Press 3x10-12", "Lat Pulldown 3x10-12", "Barbell Curl 3x12-15", "Tricep Pushdown 3x12-15"]),
                        TrainingDay(label: "Lower A", items: ["Back Squat 4x8-10", "Romanian Deadlift 4x8-10", "Leg Press 3x10-12", "Leg Curl 3x12-15", "Standing Calf Raise 4x15-20"]),
                        TrainingDay(label: "Upper B", items: ["Incline DB Press 4x8-10", "Pull-Up 4x8-10", "DB Shoulder Press 3x10-12", "Seated Cable Row 3x10-12", "Hammer Curl 3x12-15", "Overhead Tricep Extension 3x12-15"]),
                        TrainingDay(label: "Lower B", items: ["Deadlift 4x6-8", "Front Squat 3x10-12", "Walking Lunges 3x12/leg", "Leg Extension 3x12-15", "Seated Calf Raise 4x15-20"]),
                    ]
                ),
                ProgramVariant(
                    name: "Push/Pull/Legs + Upper",
                    description: "Adds an extra upper-body day for arm and shoulder emphasis.",
                    days: [
                        TrainingDay(label: "Push", items: ["Flat Bench Press 4x8-10", "Incline DB Press 3x10-12", "Overhead Press 3x8-10", "Lateral Raise 3x12-15", "Tricep Dip 3x10-12"]),
                        TrainingDay(label: "Pull", items: ["Deadlift 3x6-8", "Pull-Up 4x8-10", "Barbell Row 3x8-10", "Face Pull 3x15", "EZ-Bar Curl 3x10-12"]),
                        TrainingDay(label: "Legs", items: ["Back Squat 4x8-10", "Leg Press 3x10-12", "Leg Curl 3x12-15", "Leg Extension 3x12-15", "Calf Raise 4x15-20"]),
                        TrainingDay(label: "Upper · Arms & Shoulders", items: ["DB Shoulder Press 3x10-12", "Cable Lateral Raise 3x12-15", "Close-Grip Bench 3x10-12", "Preacher Curl 3x10-12", "Skull Crusher 3x10-12", "Cable Curl 3x12-15"]),
                    ]
                ),
                ProgramVariant(
                    name: "Body Part Split",
                    description: "Traditional bodybuilder split; more focused volume per muscle group each session.",
                    days: [
                        TrainingDay(label: "Chest & Triceps", items: ["Bench Press 4x8-10", "Incline DB Press 3x10-12", "Cable Fly 3x12-15", "Tricep Pushdown 3x12-15", "Overhead Tricep Extension 3x10-12"]),
                        TrainingDay(label: "Back & Biceps", items: ["Deadlift 3x6-8", "Pull-Up 4x8-10", "Barbell Row 3x8-10", "Barbell Curl 3x10-12", "Hammer Curl 3x12-15"]),
                        TrainingDay(label: "Legs", items: ["Squat 4x8-10", "Leg Press 3x10-12", "Romanian Deadlift 3x10-12", "Leg Extension 3x12-15", "Calf Raise 4x15-20"]),
                        TrainingDay(label: "Shoulders & Arms", items: ["Overhead Press 4x8-10", "Lateral Raise 3x12-15", "Rear Delt Fly 3x12-15", "EZ-Bar Curl 3x10-12", "Tricep Dip 3x10-12"]),
                    ]
                ),
            ],
            .sixDay: [
                ProgramVariant(
                    name: "Push/Pull/Legs ×2",
                    description: "Each split hit twice per week for maximum volume; great for intermediate/advanced lifters.",
                    days: [
                        TrainingDay(label: "Push A", items: ["Bench Press 4x8-10", "OHP 3x10-12", "Incline DB Press 3x10-12", "Lateral Raise 3x15", "Tricep Pushdown 3x12-15"]),
                        TrainingDay(label: "Pull A", items: ["Deadlift 3x6-8", "Pull-Up 4x8-10", "Barbell Row 3x8-10", "Curl 3x12-15"]),
                        TrainingDay(label: "Legs A", items: ["Squat 4x8-10", "Leg Press 3x10-12", "Leg Curl 3x12-15", "Calf Raise 4x15-20"]),
                        TrainingDay(label: "Push B", items: ["Incline Bench 4x8-10", "DB Shoulder Press 3x10-12", "Cable Fly 3x12-15", "Dips 3x10-12"]),
                        TrainingDay(label: "Pull B", items: ["Barbell Row 4x8-10", "Lat Pulldown 3x10-12", "Face Pull 3x15", "Hammer Curl 3x12-15"]),
                        TrainingDay(label: "Legs B", items: ["Front Squat 4x8-10", "Romanian Deadlift 3x10-12", "Walking Lunges 3x12/leg", "Seated Calf Raise 4x15-20"]),
                    ]
                ),
                ProgramVariant(
                    name: "Bro Split",
                    description: "Maximum focused volume per muscle group, one recovery day built in across the six.",
                    days: [
                        TrainingDay(label: "Chest", items: ["Bench Press 4x8-10", "Incline DB Press 4x10-12", "Cable Fly 3x12-15", "Dips 3x10-12"]),
                        TrainingDay(label: "Back", items: ["Deadlift 3x6-8", "Pull-Up 4x8-10", "Barbell Row 4x8-10", "Straight-Arm Pulldown 3x12-15"]),
                        TrainingDay(label: "Legs", items: ["Squat 4x8-10", "Leg Press 4x10-12", "Leg Curl 3x12-15", "Calf Raise 4x15-20"]),
                        TrainingDay(label: "Shoulders", items: ["OHP 4x8-10", "Lateral Raise 4x12-15", "Rear Delt Fly 3x12-15", "Shrugs 3x12-15"]),
                        TrainingDay(label: "Arms", items: ["Barbell Curl 4x10-12", "Hammer Curl 3x12-15", "Close-Grip Bench 4x10-12", "Tricep Pushdown 3x12-15"]),
                        TrainingDay(label: "Weak Point / Repeat", items: ["Pick your lagging muscle group — extra volume at moderate intensity"]),
                    ]
                ),
                ProgramVariant(
                    name: "Upper / Lower ×3",
                    description: "Higher frequency (3×/week per muscle group) while still allowing daily variety.",
                    days: [
                        TrainingDay(label: "Upper A", items: ["Bench Press 4x8-10", "Row 4x8-10", "Lateral Raise 3x12-15", "Curl 3x12-15"]),
                        TrainingDay(label: "Lower A", items: ["Squat 4x8-10", "Leg Curl 3x12-15", "Calf Raise 4x15-20"]),
                        TrainingDay(label: "Upper B", items: ["OHP 4x8-10", "Pull-Up 4x8-10", "Tricep Pushdown 3x12-15"]),
                        TrainingDay(label: "Lower B", items: ["Deadlift 3x6-8", "Leg Press 3x10-12", "Walking Lunges 3x12/leg"]),
                        TrainingDay(label: "Upper C", items: ["Incline DB Press 4x10-12", "Cable Row 4x10-12", "Face Pull 3x15"]),
                        TrainingDay(label: "Lower C", items: ["Front Squat 4x8-10", "Romanian Deadlift 3x10-12", "Seated Calf Raise 4x15-20"]),
                    ]
                ),
            ],
        ],
        .powerlifting: [
            .fourDay: [
                ProgramVariant(
                    name: "Classic SBD Split",
                    description: "One day dedicated to each competition lift, plus an accessory day.",
                    days: [
                        TrainingDay(label: "Squat", items: ["Back Squat 5x5", "Pause Squat 3x3", "Leg Press 3x8", "Ab Wheel 3x10"]),
                        TrainingDay(label: "Bench", items: ["Bench Press 5x5", "Close-Grip Bench 3x5", "DB Row 3x10", "Tricep Pushdown 3x12"]),
                        TrainingDay(label: "Deadlift", items: ["Deadlift 5x3", "Deficit Deadlift 3x5", "Barbell Row 3x8", "Back Extension 3x10"]),
                        TrainingDay(label: "Accessory / Overhead", items: ["Overhead Press 4x6", "Front Squat 3x6", "Pull-Up 3x8", "Farmer's Carry 3x40yd"]),
                    ]
                ),
                ProgramVariant(
                    name: "Upper / Lower ×2",
                    description: "Splits pressing/pulling work from squat/deadlift work, run twice weekly.",
                    days: [
                        TrainingDay(label: "Lower · Squat Focus", items: ["Back Squat 5x5", "Romanian Deadlift 3x6", "Leg Press 3x8"]),
                        TrainingDay(label: "Upper · Bench Focus", items: ["Bench Press 5x5", "Overhead Press 3x6", "Barbell Row 3x8"]),
                        TrainingDay(label: "Lower · Deadlift Focus", items: ["Deadlift 5x3", "Front Squat 3x6", "Good Morning 3x8"]),
                        TrainingDay(label: "Upper · Volume", items: ["Incline Bench 4x6", "Weighted Pull-Up 3x6", "Close-Grip Bench 3x8"]),
                    ]
                ),
                ProgramVariant(
                    name: "Max / Dynamic Effort",
                    description: "Alternates heavy singles/triples with fast submaximal speed work — a simplified Westside approach.",
                    days: [
                        TrainingDay(label: "ME Lower", items: ["Squat variation — work up to a heavy 1-3RM", "Leg Curl 3x8", "Ab Work"]),
                        TrainingDay(label: "ME Upper", items: ["Bench variation — work up to a heavy 1-3RM", "Barbell Row 3x8", "Tricep Work"]),
                        TrainingDay(label: "DE Lower", items: ["Speed Squats 8x2 @ 55-60%", "Deadlift (moderate) 4x3", "Reverse Hyper 3x10"]),
                        TrainingDay(label: "DE Upper", items: ["Speed Bench 8x3 @ 50-55%", "DB Shoulder Press 3x8", "Face Pull 3x15"]),
                    ]
                ),
            ],
            .sixDay: [
                ProgramVariant(
                    name: "SBD ×2 · Varied Intensity",
                    description: "Each main lift trained twice weekly with different rep schemes (heavy day + volume day).",
                    days: [
                        TrainingDay(label: "Squat · Heavy", items: ["Back Squat 5x3", "Pause Squat 3x3"]),
                        TrainingDay(label: "Bench · Heavy", items: ["Bench Press 5x3", "Close-Grip Bench 3x5"]),
                        TrainingDay(label: "Deadlift · Heavy", items: ["Deadlift 5x2", "Deficit Deadlift 3x3"]),
                        TrainingDay(label: "Squat · Volume", items: ["Front Squat 4x8", "Leg Press 3x10"]),
                        TrainingDay(label: "Bench · Volume", items: ["Incline Bench 4x8", "DB Bench 3x10"]),
                        TrainingDay(label: "Deadlift · Volume", items: ["Romanian Deadlift 4x8", "Barbell Row 3x10"]),
                    ]
                ),
                ProgramVariant(
                    name: "Full Conjugate Method",
                    description: "True Westside-style template with two hypertrophy days added for muscle support.",
                    days: [
                        TrainingDay(label: "ME Lower", items: ["Heavy squat/deadlift variation to a 1-3RM"]),
                        TrainingDay(label: "ME Upper", items: ["Heavy bench variation to a 1-3RM"]),
                        TrainingDay(label: "Hypertrophy A", items: ["Leg Press 4x10", "Leg Curl 3x12", "Ab Work"]),
                        TrainingDay(label: "DE Lower", items: ["Speed Squats 8x2", "Speed Deadlifts 6x1"]),
                        TrainingDay(label: "DE Upper", items: ["Speed Bench 8x3", "Band / Chain Work"]),
                        TrainingDay(label: "Hypertrophy B", items: ["DB Row 4x10", "Lateral Raise 3x15", "Tricep / Bicep Superset"]),
                    ]
                ),
                ProgramVariant(
                    name: "Daily Undulating (DUP)",
                    description: "Squat, bench, and deadlift each trained across the week with rotating heavy/moderate/light intensities.",
                    days: [
                        TrainingDay(label: "Heavy Squat · Light Bench", items: ["Back Squat 3x3 @ 85-90%", "Bench Press 3x8 @ 65%"]),
                        TrainingDay(label: "Heavy Deadlift", items: ["Deadlift 3x3 @ 85-90%", "Accessory Pull Work"]),
                        TrainingDay(label: "Heavy Bench · Light Squat", items: ["Bench Press 3x3 @ 85-90%", "Back Squat 3x8 @ 65%"]),
                        TrainingDay(label: "Rest / Mobility", items: []),
                        TrainingDay(label: "Moderate Squat & Bench", items: ["Back Squat 4x5 @ 75%", "Bench Press 4x5 @ 75%"]),
                        TrainingDay(label: "Moderate Deadlift", items: ["Deadlift 4x5 @ 75%", "Upper Accessory Work"]),
                    ]
                ),
            ],
        ],
        .toning: [
            .fourDay: [
                ProgramVariant(
                    name: "Full-Body Circuit ×4",
                    description: "Each session hits the whole body with a different emphasis, kept fast-paced for a cardio effect.",
                    days: [
                        TrainingDay(label: "Full Body A", items: ["Goblet Squat 3x15", "DB Row 3x15", "Push-Up 3x15", "Plank 3x30s"]),
                        TrainingDay(label: "Full Body B", items: ["Walking Lunge 3x12/leg", "Lat Pulldown 3x15", "DB Shoulder Press 3x15", "Bicycle Crunch 3x20"]),
                        TrainingDay(label: "Full Body C", items: ["Romanian Deadlift 3x15", "Cable Row 3x15", "Incline DB Press 3x15", "Side Plank 3x30s/side"]),
                        TrainingDay(label: "Full Body D", items: ["Step-Ups 3x12/leg", "Face Pull 3x15", "Lateral Raise 3x15", "Mountain Climbers 3x30s"]),
                    ]
                ),
                ProgramVariant(
                    name: "Upper / Lower Toning",
                    description: "Each region trained twice weekly with light-moderate weight and short rest for an endurance stimulus.",
                    days: [
                        TrainingDay(label: "Upper A", items: ["Push-Up 3x15", "Seated Row 3x15", "DB Shoulder Press 3x15", "Tricep Kickback 3x15"]),
                        TrainingDay(label: "Lower A", items: ["Goblet Squat 3x15", "Glute Bridge 3x15", "Calf Raise 3x20"]),
                        TrainingDay(label: "Upper B", items: ["Incline DB Press 3x15", "Lat Pulldown 3x15", "Lateral Raise 3x15", "Curl 3x15"]),
                        TrainingDay(label: "Lower B", items: ["Romanian Deadlift 3x15", "Walking Lunge 3x12/leg", "Side-Lying Leg Raise 3x15/side"]),
                    ]
                ),
                ProgramVariant(
                    name: "Push / Pull / Legs / Core",
                    description: "Adds a dedicated core & conditioning day for definition around the midsection.",
                    days: [
                        TrainingDay(label: "Push", items: ["Push-Up 3x15", "DB Shoulder Press 3x15", "Cable Fly 3x15"]),
                        TrainingDay(label: "Pull", items: ["Seated Row 3x15", "Lat Pulldown 3x15", "Rear Delt Fly 3x15"]),
                        TrainingDay(label: "Legs", items: ["Goblet Squat 3x15", "Lunge 3x12/leg", "Leg Curl 3x15"]),
                        TrainingDay(label: "Core & Conditioning", items: ["Plank 3x40s", "Russian Twist 3x20", "Mountain Climbers 3x30s", "Incline Walk / Bike 15 min"]),
                    ]
                ),
            ],
            .sixDay: [
                ProgramVariant(
                    name: "Full-Body ×6 · Light & Frequent",
                    description: "High-frequency, lighter-weight sessions for consistent calorie burn and muscle tone without excessive fatigue.",
                    days: [
                        TrainingDay(label: "Full Body A", items: ["Squat", "Push-Up", "Row", "Plank"]),
                        TrainingDay(label: "Full Body B", items: ["Lunge", "Shoulder Press", "Lat Pulldown", "Bicycle Crunch"]),
                        TrainingDay(label: "Full Body C", items: ["Deadlift", "Incline Press", "Cable Row", "Side Plank"]),
                        TrainingDay(label: "Full Body D", items: ["Step-Up", "Face Pull", "Lateral Raise", "Mountain Climbers"]),
                        TrainingDay(label: "Full Body E", items: ["Goblet Squat", "Push-Up Variation", "Seated Row", "Russian Twist"]),
                        TrainingDay(label: "Full Body F", items: ["Glute Bridge", "DB Press", "Pulldown", "Superman Hold"]),
                    ]
                ),
                ProgramVariant(
                    name: "Body Part + Cardio Finishers",
                    description: "More targeted muscle work with a short cardio burst at the end of every session for extra definition.",
                    days: [
                        TrainingDay(label: "Chest & Triceps", items: ["Targeted chest & tricep work", "Cardio finisher 10 min"]),
                        TrainingDay(label: "Back & Biceps", items: ["Targeted back & bicep work", "Cardio finisher 10 min"]),
                        TrainingDay(label: "Legs", items: ["Targeted leg work", "Cardio finisher 10 min"]),
                        TrainingDay(label: "Shoulders", items: ["Targeted shoulder work", "Cardio finisher 10 min"]),
                        TrainingDay(label: "Glutes & Core", items: ["Targeted glute & core work", "Cardio finisher 10 min"]),
                        TrainingDay(label: "Full-Body Circuit", items: ["Light high-rep full-body circuit", "Cardio 15 min"]),
                    ]
                ),
                ProgramVariant(
                    name: "Push/Pull/Legs ×2 · Toning",
                    description: "PPL ×2 structure with lighter loads, higher reps, and shorter rest for a leaner, endurance-focused stimulus.",
                    days: [
                        TrainingDay(label: "Push A", items: ["Push-Up 3x15", "DB Shoulder Press 3x15", "Cable Fly 3x15"]),
                        TrainingDay(label: "Pull A", items: ["Seated Row 3x15", "Lat Pulldown 3x15", "Rear Delt Fly 3x15"]),
                        TrainingDay(label: "Legs A", items: ["Goblet Squat 3x15", "Leg Curl 3x15", "Calf Raise 3x20"]),
                        TrainingDay(label: "Push B", items: ["Incline DB Press 3x15", "Lateral Raise 3x15", "Tricep Kickback 3x15"]),
                        TrainingDay(label: "Pull B", items: ["Cable Row 3x15", "Face Pull 3x15", "Curl 3x15"]),
                        TrainingDay(label: "Legs B", items: ["Romanian Deadlift 3x15", "Walking Lunge 3x12/leg", "Glute Bridge 3x15"]),
                    ]
                ),
            ],
        ],
    ]

    public static func variants(for category: LiftCategory, frequency: TrainingFrequency) -> [ProgramVariant] {
        programs[category]?[frequency] ?? []
    }
}
