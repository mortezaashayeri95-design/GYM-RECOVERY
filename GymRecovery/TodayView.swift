import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var comingSoon: String?
    private let workout = SampleData.pushDay
    private let lastWorkout = SampleData.lastWorkout

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    weekStrip
                    recoveryStatus
                    plannedWorkout
                    quickActions
                    restTimes
                    challenge
                    recentActivity
                }
                .padding()
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .alert(comingSoon ?? "", isPresented: Binding(
                get: { comingSoon != nil },
                set: { if !$0 { comingSoon = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This is coming in a later version.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                Text(model.profile.name.isEmpty ? "Today" : "Hi, \(model.profile.name)!")
                    .font(.largeTitle.bold())
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.heart)
                Text("\(model.profile.restingHeartRate)")
                    .font(.headline.monospacedDigit())
                Text("bpm resting")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.card, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.08)))
            .accessibilityElement(children: .combine)
        }
    }

    private var weekStrip: some View {
        HStack(spacing: 6) {
            ForEach(SampleData.week()) { day in
                VStack(spacing: 6) {
                    Text(day.letter)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text(day.status.label)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .foregroundStyle(day.status == .done ? Theme.onAccent : (day.status == .today ? Theme.accent : .white))
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(day.status == .done ? Theme.accent : (day.status == .planned ? Theme.cardInner : Theme.card))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(day.status == .today ? Theme.accent : Color.white.opacity(0.08), lineWidth: day.status == .today ? 1.5 : 1)
                        )
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Cards

    private var recoveryStatus: some View {
        HStack(spacing: 16) {
            ReadinessRing(score: SampleData.readinessScore, size: 108)
            VStack(alignment: .leading, spacing: 6) {
                Text("Recovery status")
                    .sectionLabel(.white)
                Text("You're well recovered. A good day to push on strength.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                VStack(alignment: .leading, spacing: 4) {
                    Label("Effort: steady", systemImage: "bolt.fill")
                        .foregroundStyle(Theme.effort)
                    Label("Recovery: good", systemImage: "arrow.clockwise")
                        .foregroundStyle(Theme.recovery)
                }
                .font(.caption.weight(.semibold))
            }
        }
        .card()
    }

    private var plannedWorkout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planned workout")
                .sectionLabel()
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.title.bold())
                Text("\(workout.totalSets) sets · about \(workout.estimatedMinutes) min · \(workout.focus)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            VStack(spacing: 8) {
                ForEach(workout.exercises) { exercise in
                    HStack {
                        Text(exercise.name)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(exercise.detail)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Theme.cardInner, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            PrimaryButton(title: model.workout.isRunning ? "Continue workout" : "Start workout", systemImage: "play.fill") {
                model.startWorkout()
            }
            .padding(.top, 4)
        }
        .card()
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickAction("Push routine", systemImage: "dumbbell") { model.startWorkout() }
            quickAction("Free cardio", systemImage: "figure.run") { comingSoon = "Free cardio" }
            quickAction("New workout", systemImage: "plus") { comingSoon = "New workout" }
        }
    }

    private func quickAction(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .padding(12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    private var restTimes: some View {
        let goal = model.profile.goal
        return VStack(alignment: .leading, spacing: 12) {
            Text("Your rest times for this profile")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            HStack(spacing: 10) {
                restTile(RecoveryEngine.bigLiftRest(goal: goal), "Big lifts, first set")
                restTile(RecoveryEngine.isolationRest(goal: goal), "Isolation lifts")
            }
            Text("Based on your \(goal.title.lowercased()) goal. Rest grows when your heart rate peaks above \(Int(Double(RecoveryEngine.estimatedMaxHeartRate(age: model.profile.age)) * RecoveryEngine.highPeakShare)) bpm, about 85% of the estimate for age \(model.profile.age).")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .card()
    }

    private func restTile(_ seconds: Int, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(RecoveryEngine.format(seconds))
                .font(Theme.display(30).monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.cardInner, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var challenge: some View {
        let challenge = SampleData.challenge
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your challenges")
                    .sectionLabel(.white)
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.milestone)
            }
            Text("\(challenge.remaining) \(challenge.remaining == 1 ? "workout" : "workouts") left: \(challenge.title)")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.milestone, Theme.accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * challenge.progress)
                }
            }
            .frame(height: 10)
            .accessibilityLabel("\(challenge.completed) of \(challenge.goal) workouts done")
        }
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.milestone.opacity(0.5), lineWidth: 1)
        )
    }

    private var recentActivity: some View {
        NavigationLink {
            WorkoutSummaryView(log: lastWorkout)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent activity")
                        .sectionLabel(.white)
                    Text("\(lastWorkout.date.formatted(.dateTime.weekday(.wide))) · \(lastWorkout.name) · \(lastWorkout.durationMinutes) min")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.secondaryText)
            }
            .card()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView()
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
