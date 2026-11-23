import SwiftUI

/// "Micro-milestones" on the Watch: the latest record and this week's challenge.
struct WatchMilestonesView: View {
    var body: some View {
        let challenge = SampleData.challenge
        let now = SampleData.volumeComparison.map(\.now).reduce(0, +)
        let last = SampleData.volumeComparison.map(\.last).reduce(0, +)
        let change = last > 0 ? Int(((now - last) / last * 100).rounded()) : 0

        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.milestone)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Theme.milestone.opacity(0.25)))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(SampleData.newRecord.title)
                            .font(.headline)
                        Text(SampleData.newRecord.detail)
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.footnote.weight(.semibold))
                    ProgressView(value: challenge.progress)
                        .tint(Theme.milestone)
                    Text("\(challenge.completed) of \(challenge.goal) done")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(10)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                HStack {
                    Text("You vs last time")
                        .font(.footnote)
                    Spacer()
                    Text("\(change >= 0 ? "+" : "")\(change)%")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .navigationTitle("Milestones")
    }
}

#Preview {
    WatchMilestonesView()
}
