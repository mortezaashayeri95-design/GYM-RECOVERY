import SwiftUI

/// "Insight & Recovery" on the Watch: readiness and the coach's next step.
struct WatchInsightView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ReadinessRing(score: SampleData.readinessScore, size: 104)
                HStack(spacing: 10) {
                    legend("Effort", Theme.effort)
                    legend("Recovery", Theme.recovery)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT STEP")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.accent)
                    Text(SampleData.nextStep)
                        .font(.footnote)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LinearGradient(colors: [Theme.effort, Theme.recovery], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                )
            }
        }
        .navigationTitle("Readiness")
    }

    private func legend(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Capsule().fill(color).frame(width: 10, height: 3)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

#Preview {
    WatchInsightView()
}
