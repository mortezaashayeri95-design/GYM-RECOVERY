import Foundation
import Observation

enum TrainingGoal: String, CaseIterable, Identifiable, Codable {
    case strength, muscle, endurance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strength: "Strength"
        case .muscle: "Muscle size"
        case .endurance: "Endurance"
        }
    }

    /// Starting rest before the recovery engine adjusts it, in seconds.
    /// Placeholder values: check them with a trainer before release.
    var baseRest: Int {
        switch self {
        case .strength: 150
        case .muscle: 90
        case .endurance: 45
        }
    }
}

/// The person training. Shared by every screen so rest times follow their profile.
@Observable
final class UserProfile {
    var name = ""
    var age = 28
    var weightKg = 72.0
    var goal: TrainingGoal = .muscle
    var restingHeartRate = 65
}

struct Exercise: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var sets: Int
    var reps: Int
    var weightKg: Double?
    /// Big multi-joint lifts get longer rest than isolation lifts.
    var isCompound = false

    var detail: String {
        guard let weightKg else { return "\(sets) × \(reps)" }
        return "\(sets) × \(reps) · \(weightKg.formatted()) kg"
    }

    var setDetail: String {
        guard let weightKg else { return "\(reps) reps" }
        return "\(reps) reps · \(weightKg.formatted()) kg"
    }
}

struct Workout: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var focus: String
    var exercises: [Exercise]
    var estimatedMinutes: Int

    var totalSets: Int { exercises.map(\.sets).reduce(0, +) }
}

struct RestRecord: Identifiable, Hashable, Codable {
    var id = UUID()
    var exerciseName: String
    var restSeconds: Int
    var suggestedSeconds: Int

    var isTooShort: Bool { restSeconds < suggestedSeconds - 10 }
}

struct WorkoutLog: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var date: Date
    var durationMinutes: Int
    var sets: Int
    var averageHeartRate: Int
    var rests: [RestRecord]

    var averageRest: Int {
        guard !rests.isEmpty else { return 0 }
        return rests.map(\.restSeconds).reduce(0, +) / rests.count
    }
}

enum DayStatus {
    case done, today, planned, rest

    var label: String {
        switch self {
        case .done: "Done"
        case .today: "Now"
        case .planned: "Plan"
        case .rest: "Off"
        }
    }
}

struct WeekDay: Identifiable {
    let id: Int
    let letter: String
    let status: DayStatus
}

/// One set in the effort and recovery chart. Both values are 0–100.
struct SetInsight: Identifiable {
    let id: Int
    let effort: Double
    let recovery: Double
}

/// Training volume (kg × reps) per exercise, this session and last time.
struct VolumeComparison: Identifiable {
    let id: Int
    let exercise: String
    let now: Double
    let last: Double
}

struct Challenge {
    let title: String
    let completed: Int
    let goal: Int

    var remaining: Int { max(0, goal - completed) }
    var progress: Double { goal == 0 ? 0 : Double(completed) / Double(goal) }
}
