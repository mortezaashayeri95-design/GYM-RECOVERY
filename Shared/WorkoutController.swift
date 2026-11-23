import Foundation
import Observation
#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#endif

enum WorkoutPhase {
    case set, effort, rest, ready, done
}

/// Drives a workout on iPhone or Apple Watch: set → rate effort → rest → ready → next set.
@MainActor
@Observable
final class WorkoutController {
    let workout: Workout
    let profile: UserProfile
    /// 1 (easy) to 5 (maximum).
    var effort = 3
    let heartRate = HeartRateMonitor()

    private(set) var isRunning = false
    private(set) var phase: WorkoutPhase = .set
    private(set) var exerciseIndex = 0
    private(set) var setNumber = 1
    private(set) var suggestion: RestSuggestion?
    private(set) var restTotal = 0
    private(set) var restRemaining = 0
    private(set) var restElapsed = 0
    private(set) var restLog: [RestRecord] = []
    /// Heart rate when the last set ended, close to its peak.
    private(set) var setEndHeartRate: Int?

    @ObservationIgnored private var timerTask: Task<Void, Never>?

    init(workout: Workout = SampleData.pushDay, profile: UserProfile) {
        self.workout = workout
        self.profile = profile
    }

    var exercise: Exercise { workout.exercises[exerciseIndex] }

    var isLastSet: Bool {
        exerciseIndex == workout.exercises.count - 1 && setNumber == exercise.sets
    }

    /// Sets finished so far across the whole workout.
    var completedSets: Int {
        workout.exercises.prefix(exerciseIndex).map(\.sets).reduce(0, +) + setNumber - 1
    }

    var restProgress: Double {
        guard restTotal > 0 else { return 0 }
        return Double(restRemaining) / Double(restTotal)
    }

    var isRecovered: Bool {
        RecoveryEngine.isRecovered(heartRate: heartRate.heartRate, restingHeartRate: profile.restingHeartRate)
    }

    /// The set that starts after the current rest, for example "Overhead press · set 3 of 3".
    var nextSetDescription: String {
        if setNumber < exercise.sets {
            return "\(exercise.name) · set \(setNumber + 1) of \(exercise.sets)"
        }
        let next = workout.exercises[min(exerciseIndex + 1, workout.exercises.count - 1)]
        return "\(next.name) · set 1 of \(next.sets)"
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        heartRate.start()
        heartRate.isWorking = true
    }

    func finishSet() {
        setEndHeartRate = heartRate.heartRate
        heartRate.isWorking = false
        if isLastSet {
            heartRate.stop()
            phase = .done
        } else {
            phase = .effort
        }
    }

    func startRest() {
        let suggestion = RecoveryEngine.suggestRest(
            goal: profile.goal,
            isCompound: exercise.isCompound,
            effort: effort,
            heartRate: setEndHeartRate,
            age: profile.age
        )
        self.suggestion = suggestion
        restTotal = suggestion.seconds
        restRemaining = suggestion.seconds
        restElapsed = 0
        phase = .rest

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                self.tick()
            }
        }
    }

    func addTime(_ seconds: Int = 15) {
        restRemaining += seconds
        restTotal += seconds
    }

    func skipRest() {
        finishRest()
    }

    func startNextSet() {
        if setNumber < exercise.sets {
            setNumber += 1
        } else {
            exerciseIndex += 1
            setNumber = 1
        }
        effort = 3
        heartRate.isWorking = true
        phase = .set
    }

    func end() {
        timerTask?.cancel()
        timerTask = nil
        heartRate.stop()
        isRunning = false
        phase = .done
    }

    func restart() {
        timerTask?.cancel()
        exerciseIndex = 0
        setNumber = 1
        effort = 3
        restLog = []
        suggestion = nil
        phase = .set
        isRunning = false
        start()
    }

    private func tick() {
        restElapsed += 1
        restRemaining -= 1
        if restRemaining <= 0 {
            finishRest()
        }
    }

    private func finishRest() {
        timerTask?.cancel()
        timerTask = nil
        restLog.append(RestRecord(
            exerciseName: exercise.name,
            restSeconds: restElapsed,
            suggestedSeconds: suggestion?.seconds ?? restElapsed
        ))
        playReadyHaptic()
        phase = .ready
    }

    private func playReadyHaptic() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #elseif os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
