import SwiftUI

struct WorkoutSummaryView: View {
    let log: WorkoutLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(log.date.formatted(.dateTime.weekday(.wide))) · \(log.durationMinutes) min · \(log.rests.count) exercises")
                    .foregroundStyle(Theme.secondaryText)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    StatTile(title: "Sets", value: "\(log.sets)")
                    StatTile(title: "Avg rest", value: RecoveryEngine.format(log.averageRest))
                    StatTile(title: "Avg heart rate", value: "\(log.averageHeartRate)")
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest per exercise")
                            .font(.headline)
                        Text("Bar: your average rest · Line: suggested rest")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    let maxSeconds = max(180, log.rests.map { max($0.restSeconds, $0.suggestedSeconds) }.max() ?? 0)
                    ForEach(log.rests) { record in
                        RestBar(record: record, maxSeconds: maxSeconds)
                    }
                }
                .card()
            }
            .padding()
        }
        .navigationTitle(log.name)
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            Text(value)
                .font(.title2.bold().monospacedDigit())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct RestBar: View {
    let record: RestRecord
    let maxSeconds: Int

    private var color: Color { record.isTooShort ? Theme.effort : Theme.accent }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.exerciseName)
                    .fontWeight(.semibold)
                Spacer()
                Text(record.isTooShort ? "Too short" : "On target")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(color)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * fraction(record.restSeconds))
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(.white)
                        .frame(width: 3, height: 18)
                        .offset(x: geometry.size.width * fraction(record.suggestedSeconds) - 1.5)
                }
            }
            .frame(height: 12)
            Text("Rested \(RecoveryEngine.format(record.restSeconds)) · suggested \(RecoveryEngine.format(record.suggestedSeconds))")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(record.exerciseName): rested \(RecoveryEngine.format(record.restSeconds)), suggested \(RecoveryEngine.format(record.suggestedSeconds)), \(record.isTooShort ? "too short" : "on target")")
    }

    private func fraction(_ seconds: Int) -> CGFloat {
        CGFloat(min(seconds, maxSeconds)) / CGFloat(maxSeconds)
    }
}

#Preview {
    NavigationStack {
        WorkoutSummaryView(log: SampleData.lastWorkout)
    }
    .preferredColorScheme(.dark)
}
