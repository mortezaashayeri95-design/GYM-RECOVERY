import Foundation

/// Example content used until workouts are created, measured and synced for real.
enum SampleData {
    static let pushDay = Workout(
        name: "Push day",
        focus: "chest, shoulders, triceps",
        exercises: [
            Exercise(name: "Barbell bench press", sets: 4, reps: 8, weightKg: 60, isCompound: true),
            Exercise(name: "Incline dumbbell press", sets: 3, reps: 10, weightKg: 22, isCompound: true),
            Exercise(name: "Overhead press", sets: 3, reps: 8, weightKg: 40, isCompound: true),
            Exercise(name: "Triceps pushdown", sets: 3, reps: 12, weightKg: 25),
        ],
        estimatedMinutes: 50
    )

    static let lastWorkout = WorkoutLog(
        name: "Pull day",
        date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
        durationMinutes: 50,
        sets: 14,
        averageHeartRate: 124,
        rests: [
            RestRecord(exerciseName: "Lat pulldown", restSeconds: 100, suggestedSeconds: 130),
            RestRecord(exerciseName: "Seated row", restSeconds: 125, suggestedSeconds: 130),
            RestRecord(exerciseName: "Pull-up", restSeconds: 150, suggestedSeconds: 150),
            RestRecord(exerciseName: "Biceps curl", restSeconds: 55, suggestedSeconds: 75),
        ]
    )

    /// Placeholder: there is no validated readiness model yet.
    static let readinessScore = 84

    static let nextStep = "Keep your weights, and cut rest by 10 s on isolation lifts."

    static let setInsights: [SetInsight] = [
        (55, 80), (70, 62), (62, 74), (85, 50), (72, 66),
        (90, 45), (68, 70), (80, 58), (60, 78), (88, 52),
    ].enumerated().map { SetInsight(id: $0.offset + 1, effort: $0.element.0, recovery: $0.element.1) }

    static let newRecord = (title: "New record", detail: "+2% total volume on bench press")

    static let challenge = Challenge(title: "3 workouts this week", completed: 2, goal: 3)

    static let volumeComparison: [VolumeComparison] = [
        VolumeComparison(id: 1, exercise: "Bench", now: 1920, last: 1880),
        VolumeComparison(id: 2, exercise: "Incline", now: 1320, last: 1260),
        VolumeComparison(id: 3, exercise: "Overhead", now: 960, last: 960),
        VolumeComparison(id: 4, exercise: "Triceps", now: 900, last: 850),
    ]

    /// Training days in the plan (Monday = 0). Today always counts as a training day.
    static let trainingDays: Set<Int> = [0, 2, 4]

    static func week(on date: Date = .now) -> [WeekDay] {
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        // Calendar weekday: Sunday = 1 … Saturday = 7. Convert to Monday = 0.
        let today = (Calendar.current.component(.weekday, from: date) + 5) % 7
        return letters.enumerated().map { index, letter in
            let trains = trainingDays.contains(index)
            let status: DayStatus
            if index == today {
                status = .today
            } else if index < today {
                status = trains ? .done : .rest
            } else {
                status = trains ? .planned : .rest
            }
            return WeekDay(id: index, letter: letter, status: status)
        }
    }
}
