# Gym Recovery

An iPhone and Apple Watch app that helps gym-goers recover properly between sets and get more out of every workout. It tracks heart rate and effort, suggests how long to rest, and taps your wrist when you're ready for the next set.

Built for Challenge 2 at the Apple Developer Academy.

## Features

**iPhone**
- **Today:** weekly plan, readiness, the planned workout, rest times for your profile, challenges and recent activity.
- **Workout ("Glance & Go"):** large set counter, rest ring and heart rate you can read from a distance.
- **Progress:** readiness, effort and recovery per set, next step, milestones and a comparison with last time.
- **Coach:** a voice coach. Speak a question, the agent answers and reads the answer aloud. It uses Apple's on-device model on iOS 26 or later with Apple Intelligence, and simple rules otherwise.
- **Profile:** age, weight, resting heart rate and goal, which set the rest times.

**Apple Watch**
- Workout flow: set → rate effort → rest → ready, with live heart rate from HealthKit and a haptic tap when rest is over.
- Readiness and milestones pages.

## Requirements

- Xcode 27 or later
- iOS 18 or later, watchOS 11 or later

## Running it

1. Open `GymRecovery.xcodeproj`.
2. Choose the **GymRecovery** scheme and an iPhone simulator, then press **⌘R**.
3. To run on a device, set your team under **Signing & Capabilities** for both targets and replace the `com.example` bundle ID prefix with your own.

## Project structure

- `GymRecovery/`: iPhone app
- `GymRecoveryWatch/`: Apple Watch app
- `Shared/`: models, recovery rules, workout logic, heart rate and shared UI used by both apps
- `Config/`: entitlements

## Notes

- Readiness, records, charts and history use example data in `Shared/SampleData.swift`.
- The rest rules in `Shared/RecoveryEngine.swift` are a first prototype and still need to be checked by a trainer.
- The coach gives general training guidance, not medical advice.
