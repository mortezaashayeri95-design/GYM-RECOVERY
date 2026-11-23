import SwiftUI

/// The live workout on iPhone, styled after the "Glance & Go" prototype:
/// big numbers you can read from a distance between sets.
struct PhoneWorkoutView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let controller = model.workout
        ZStack {
            Color.black.ignoresSafeArea()
            Group {
                if !controller.isRunning && controller.phase != .done {
                    notStarted
                } else {
                    switch controller.phase {
                    case .set: setScreen(controller)
                    case .effort: effortScreen(controller)
                    case .rest: restScreen(controller)
                    case .ready: readyScreen(controller)
                    case .done: doneScreen(controller)
                    }
                }
            }
            .padding(24)
        }
    }

    private var notStarted: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text(SampleData.pushDay.name)
                .font(Theme.display(40))
            Text("\(SampleData.pushDay.totalSets) sets · about \(SampleData.pushDay.estimatedMinutes) min")
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            PrimaryButton(title: "Start workout", systemImage: "play.fill") { model.startWorkout() }
        }
    }

    private func setCounter(_ controller: WorkoutController) -> some View {
        Text("SET \(controller.setNumber)/\(controller.exercise.sets)")
            .font(Theme.display(40))
            .foregroundStyle(Theme.accent)
    }

    // MARK: - During a set

    private func setScreen(_ controller: WorkoutController) -> some View {
        VStack(spacing: 18) {
            setCounter(controller)
                .padding(.top, 24)
            VStack(spacing: 6) {
                Text(controller.exercise.name)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(controller.exercise.setDetail)
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            HeartRateLabel(bpm: controller.heartRate.heartRate, size: 72, color: Theme.accent)
            Spacer()
            PrimaryButton(title: "Set done", systemImage: "checkmark") { controller.finishSet() }
            Button("End workout", role: .destructive) { controller.end() }
                .font(.subheadline)
        }
    }

    // MARK: - Rate effort

    private func effortScreen(_ controller: WorkoutController) -> some View {
        let names = ["Easy", "Light", "Moderate", "Hard", "Max"]
        return VStack(spacing: 20) {
            Spacer()
            Text("How hard was that?")
                .font(.title.bold())
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { level in
                    let selected = level == controller.effort
                    Button {
                        controller.effort = level
                    } label: {
                        VStack(spacing: 6) {
                            Text("\(level)")
                                .font(Theme.display(28))
                                .frame(width: 54, height: 54)
                                .foregroundStyle(selected ? Color.black : Color.white)
                                .background(Circle().fill(selected ? Theme.effort : Theme.cardInner))
                            Text(names[level - 1])
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(level), \(names[level - 1])")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            Text("Your answer helps the coach choose your rest.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            PrimaryButton(title: "Start rest", systemImage: "timer") { controller.startRest() }
        }
    }

    // MARK: - Recovery

    private func restScreen(_ controller: WorkoutController) -> some View {
        VStack(spacing: 16) {
            setCounter(controller)
            RestRing(progress: controller.restProgress, remaining: controller.restRemaining, lineWidth: 16, timeSize: 72)
                .frame(width: 260, height: 260)
            HeartRateLabel(bpm: controller.heartRate.heartRate, size: 64, color: Theme.accent)
            if let reason = controller.suggestion?.reason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: 0)
            HStack(spacing: 12) {
                Button {
                    controller.addTime()
                } label: {
                    Text("+15 s").frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.white)
                PrimaryButton(title: "Skip rest") { controller.skipRest() }
            }
            .font(.headline)
        }
    }

    // MARK: - Ready

    private func readyScreen(_ controller: WorkoutController) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Theme.accent))
                .accessibilityHidden(true)
            Text("READY")
                .font(Theme.display(56))
            Text(controller.nextSetDescription)
                .font(.title3)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Text(readyDetail(controller))
                .font(.subheadline)
            Spacer()
            PrimaryButton(title: "Start set", systemImage: "play.fill") { controller.startNextSet() }
        }
    }

    private func readyDetail(_ controller: WorkoutController) -> String {
        let rested = "Rested " + RecoveryEngine.format(controller.restLog.last?.restSeconds ?? 0)
        return controller.isRecovered ? rested + " · heart rate recovered" : rested
    }

    // MARK: - Done

    private func doneScreen(_ controller: WorkoutController) -> some View {
        let onTarget = controller.restLog.filter { !$0.isTooShort }.count
        return VStack(spacing: 14) {
            Spacer()
            Image(systemName: "trophy.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.milestone)
            Text("WORKOUT DONE")
                .font(Theme.display(44))
            Text("\(controller.completedSets + (controller.isLastSet ? 1 : 0)) sets · \(onTarget) of \(controller.restLog.count) rests on target")
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            PrimaryButton(title: "See progress", systemImage: "chart.bar") { model.selectedTab = .progress }
            Button("Start again") { controller.restart() }
                .font(.subheadline)
        }
    }
}

#Preview {
    PhoneWorkoutView()
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
