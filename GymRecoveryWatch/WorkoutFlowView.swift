import SwiftUI

/// The in-workout pages, styled after the "Glance & Go" prototype.
struct WorkoutFlowView: View {
    let controller: WorkoutController

    var body: some View {
        Group {
            switch controller.phase {
            case .set: SetView(controller: controller)
            case .effort: EffortView(controller: controller)
            case .rest: RestView(controller: controller)
            case .ready: ReadyView(controller: controller)
            case .done: DoneView(controller: controller)
            }
        }
        .onAppear { controller.start() }
    }
}

// MARK: - During a set

struct SetView: View {
    let controller: WorkoutController

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SET \(controller.setNumber)/\(controller.exercise.sets)")
                .font(Theme.display(26))
                .foregroundStyle(Theme.accent)
            Text(controller.exercise.name)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(controller.exercise.setDetail)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            HeartRateLabel(bpm: controller.heartRate.heartRate, size: 30, color: Theme.accent)
                .padding(.top, 2)
            Spacer(minLength: 4)
            PrimaryButton(title: "Set done") { controller.finishSet() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Rate effort

struct EffortView: View {
    let controller: WorkoutController
    private let names = ["easy", "light", "moderate", "hard", "maximum"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How hard was that?")
                .font(.headline)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { level in
                    let selected = level == controller.effort
                    Button {
                        controller.effort = level
                    } label: {
                        Text("\(level)")
                            .font(Theme.display(18))
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .foregroundStyle(selected ? Color.black : Color.white)
                            .background(Circle().fill(selected ? Theme.effort : Color.white.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(level), \(names[level - 1])")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            HStack {
                Text("Easy")
                Spacer()
                Text("Max")
            }
            .font(.caption2)
            .foregroundStyle(Theme.secondaryText)
            Spacer(minLength: 4)
            PrimaryButton(title: "Start rest") { controller.startRest() }
        }
    }
}

// MARK: - Recovery

struct RestView: View {
    let controller: WorkoutController

    var body: some View {
        VStack(spacing: 2) {
            Text("SET \(controller.setNumber)/\(controller.exercise.sets)")
                .font(Theme.display(16))
                .foregroundStyle(Theme.accent)
            RestRing(progress: controller.restProgress, remaining: controller.restRemaining, lineWidth: 8, timeSize: 30)
                .frame(width: 100, height: 100)
            HeartRateLabel(bpm: controller.heartRate.heartRate, size: 22, color: Theme.accent)
            HStack(spacing: 6) {
                Button("+15 s") { controller.addTime() }
                Button("Skip") { controller.skipRest() }
                    .foregroundStyle(Theme.accent)
            }
            .font(.footnote.weight(.semibold))
        }
    }
}

// MARK: - Ready

struct ReadyView: View {
    let controller: WorkoutController

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.title3.bold())
                .foregroundStyle(Theme.onAccent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.accent))
                .accessibilityHidden(true)
            Text("READY")
                .font(Theme.display(28))
            Text(controller.nextSetDescription)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(readyDetail)
                .font(.caption2)
            Spacer(minLength: 4)
            PrimaryButton(title: "Start set") { controller.startNextSet() }
        }
    }

    private var readyDetail: String {
        let rested = "Rested " + RecoveryEngine.format(controller.restLog.last?.restSeconds ?? 0)
        return controller.isRecovered ? rested + " · recovered" : rested
    }
}

// MARK: - Done

struct DoneView: View {
    let controller: WorkoutController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.milestone)
                Text("WORKOUT DONE")
                    .font(Theme.display(24))
                Text(controller.workout.name)
                    .foregroundStyle(Theme.secondaryText)
                let tooShort = controller.restLog.filter(\.isTooShort).count
                Text("\(controller.restLog.count - tooShort) of \(controller.restLog.count) rests on target")
                    .font(.footnote)
                PrimaryButton(title: "Start again") { controller.restart() }
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    WorkoutFlowView(controller: WorkoutController(profile: UserProfile()))
}
