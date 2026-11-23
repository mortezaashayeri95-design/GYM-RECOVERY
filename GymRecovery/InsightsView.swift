import Charts
import SwiftUI

/// The Progress tab: "Insight & Recovery" and "Micro-milestones" from the prototypes.
struct InsightsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    readiness
                    nextStep
                    milestones
                    comparison
                    NavigationLink {
                        WorkoutSummaryView(log: SampleData.lastWorkout)
                    } label: {
                        HStack {
                            Text("Rest per exercise, last workout")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Progress")
        }
    }

    // MARK: - Insight & Recovery

    private var readiness: some View {
        VStack(spacing: 16) {
            Text("Insight & recovery")
                .sectionLabel()
                .frame(maxWidth: .infinity, alignment: .leading)
            ReadinessRing(score: SampleData.readinessScore, size: 170)
            HStack(spacing: 18) {
                legend("Effort", Theme.effort)
                legend("Recovery", Theme.recovery)
            }
            Chart(SampleData.setInsights) { point in
                AreaMark(x: .value("Set", point.id), y: .value("Effort", point.effort))
                    .foregroundStyle(LinearGradient(colors: [Theme.effort.opacity(0.35), Theme.effort.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("Set", point.id), y: .value("Value", point.effort), series: .value("Series", "Effort"))
                    .foregroundStyle(Theme.effort)
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("Set", point.id), y: .value("Value", point.recovery), series: .value("Series", "Recovery"))
                    .foregroundStyle(Theme.recovery)
                    .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .chartXScale(domain: 1...SampleData.setInsights.count)
            .chartXAxisLabel("Set")
            .frame(height: 170)
            .accessibilityLabel("Effort and recovery for each set of the last workout")
            Text("Readiness is an early estimate from your effort ratings and heart rate recovery.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .card()
    }

    private func legend(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Capsule().fill(color).frame(width: 14, height: 4)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var nextStep: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next step")
                .sectionLabel()
            Text(SampleData.nextStep)
                .font(.headline)
        }
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LinearGradient(colors: [Theme.effort, Theme.recovery], startPoint: .leading, endPoint: .trailing), lineWidth: 1.5)
        )
    }

    // MARK: - Micro-milestones

    private var milestones: some View {
        let challenge = SampleData.challenge
        return VStack(alignment: .leading, spacing: 14) {
            Text("Milestones")
                .sectionLabel(Theme.milestone)
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundStyle(Theme.milestone)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Theme.milestone.opacity(0.18)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(SampleData.newRecord.title)
                        .font(.title3.bold())
                    Text(SampleData.newRecord.detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                }
            }
            HStack(spacing: 8) {
                ForEach(0..<challenge.goal, id: \.self) { index in
                    let done = index < challenge.completed
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(done ? Theme.milestone : Theme.secondaryText)
                    if index < challenge.goal - 1 {
                        Capsule()
                            .fill(done ? Theme.milestone : Color.white.opacity(0.15))
                            .frame(height: 3)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Challenge: \(challenge.completed) of \(challenge.goal) workouts done")
            Text("\(challenge.title) · \(challenge.completed) of \(challenge.goal) done")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.milestone.opacity(0.5), lineWidth: 1)
        )
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("You vs last time")
                    .font(.headline)
                Spacer()
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
            }
            Chart(SampleData.volumeComparison) { item in
                BarMark(x: .value("Exercise", item.exercise), y: .value("Volume", item.last))
                    .foregroundStyle(by: .value("Session", "Last time"))
                    .position(by: .value("Session", "Last time"))
                BarMark(x: .value("Exercise", item.exercise), y: .value("Volume", item.now))
                    .foregroundStyle(by: .value("Session", "Today"))
                    .position(by: .value("Session", "Today"))
            }
            .chartForegroundStyleScale(["Last time": Color.white.opacity(0.3), "Today": Theme.accent])
            .frame(height: 170)
            Text("Volume is weight × reps for each exercise.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .card()
    }
}

#Preview {
    InsightsView()
        .preferredColorScheme(.dark)
}
