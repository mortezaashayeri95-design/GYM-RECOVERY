import Foundation
import Observation
#if os(watchOS)
import HealthKit
#endif

/// Reads live heart rate during a strength workout on Apple Watch.
/// The simulator and iPhone have no heart rate sensor, so they simulate values instead.
@Observable
final class HeartRateMonitor: NSObject {
    private(set) var heartRate: Int?
    /// True during a set, false while resting. Only used by the simulation.
    var isWorking = false

    @ObservationIgnored private var simulationTask: Task<Void, Never>?
    #if os(watchOS)
    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
    #endif

    func start() {
        #if os(watchOS) && !targetEnvironment(simulator)
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let heartRateType = HKQuantityType(.heartRate)
        store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [heartRateType]) { [weak self] granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { self?.beginSession() }
        }
        #else
        startSimulation()
        #endif
    }

    func stop() {
        simulationTask?.cancel()
        simulationTask = nil
        #if os(watchOS)
        guard let session, let builder else { return }
        session.end()
        builder.endCollection(withEnd: .now) { _, _ in
            builder.finishWorkout { _, _ in }
        }
        self.session = nil
        self.builder = nil
        #endif
    }

    private func startSimulation() {
        heartRate = 90
        simulationTask?.cancel()
        simulationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                let target = self.isWorking ? 165 : 85
                let current = self.heartRate ?? 90
                self.heartRate = current + max(-4, min(5, target - current))
            }
        }
    }

    #if os(watchOS)
    private func beginSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder
            let start = Date.now
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { _, _ in }
        } catch {
            // Without a session the app still works, just without live heart rate.
            heartRate = nil
        }
    }
    #endif
}

#if os(watchOS)
extension HeartRateMonitor: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heartRateType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(heartRateType),
              let quantity = workoutBuilder.statistics(for: heartRateType)?.mostRecentQuantity() else { return }
        let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        DispatchQueue.main.async { self.heartRate = Int(bpm.rounded()) }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

extension HeartRateMonitor: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}
#endif
