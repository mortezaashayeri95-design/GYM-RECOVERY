import Foundation

struct RestSuggestion: Equatable {
    let seconds: Int
    let reason: String
}

/// Suggests rest between sets from the goal, the kind of lift, the effort rating and heart rate.
/// The rules are a first prototype: validate them with trainers and user tests.
enum RecoveryEngine {
    /// Heart rate within this margin of resting counts as recovered.
    static let recoveredHeartRateMargin = 45
    /// A set that peaks above this share of max heart rate gets extra rest.
    static let highPeakShare = 0.85

    /// The common "220 minus age" estimate. It is rough and varies a lot between people.
    static func estimatedMaxHeartRate(age: Int) -> Int {
        220 - age
    }

    /// Rest before the first set of a big lift such as bench press.
    static func bigLiftRest(goal: TrainingGoal) -> Int {
        roundToFive(Double(goal.baseRest) * 1.45)
    }

    /// Rest for isolation lifts such as triceps pushdowns.
    static func isolationRest(goal: TrainingGoal) -> Int {
        roundToFive(Double(goal.baseRest) * 0.83)
    }

    /// - Parameters:
    ///   - effort: 1 (easy) to 5 (maximum).
    ///   - heartRate: heart rate at the end of the set, near its peak.
    static func suggestRest(goal: TrainingGoal, isCompound: Bool, effort: Int, heartRate: Int?, age: Int) -> RestSuggestion {
        let base = isCompound ? bigLiftRest(goal: goal) : isolationRest(goal: goal)
        var seconds = Double(base)
        var longer: [String] = []
        var shorter: [String] = []

        switch effort {
        case 5:
            seconds *= 1.25
            longer.append("your last set was very hard")
        case 4:
            seconds *= 1.15
            longer.append("your last set felt hard")
        case 1, 2:
            seconds *= 0.85
            shorter.append("your last set felt easy")
        default:
            break
        }

        let peakLimit = Double(estimatedMaxHeartRate(age: age)) * highPeakShare
        if let heartRate, Double(heartRate) >= peakLimit {
            seconds += 20
            longer.append("your heart rate peaked high")
        }

        let rounded = min(300, max(30, roundToFive(seconds)))
        let reason: String
        if rounded > base {
            reason = "Longer rest: " + longer.joined(separator: " and ") + "."
        } else if rounded < base {
            reason = "Shorter rest: " + shorter.joined(separator: " and ") + "."
        } else {
            reason = isCompound ? "Standard rest for a big lift." : "Standard rest for an isolation lift."
        }
        return RestSuggestion(seconds: rounded, reason: reason)
    }

    static func isRecovered(heartRate: Int?, restingHeartRate: Int) -> Bool {
        guard let heartRate else { return false }
        return heartRate - restingHeartRate <= recoveredHeartRateMargin
    }

    /// Formats seconds as m:ss, for example 125 → "2:05".
    static func format(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        return "\(clamped / 60):" + String(format: "%02d", clamped % 60)
    }

    private static func roundToFive(_ seconds: Double) -> Int {
        Int((seconds / 5).rounded()) * 5
    }
}
