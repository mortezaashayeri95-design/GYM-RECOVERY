import SwiftUI

/// The rest countdown ring from the "Glance & Go" prototype.
struct RestRing: View {
    let progress: Double
    let remaining: Int
    var lineWidth: CGFloat = 12
    var timeSize: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            VStack(spacing: 0) {
                Text("REST")
                    .font(Theme.display(timeSize * 0.42))
                    .foregroundStyle(Theme.accent)
                Text(RecoveryEngine.format(remaining))
                    .font(Theme.display(timeSize).monospacedDigit())
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText(countsDown: true))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rest, \(RecoveryEngine.format(remaining)) remaining")
    }
}

/// Readiness from the "Insight & Recovery" prototype: recovery outside, effort inside.
struct ReadinessRing: View {
    let score: Int
    var effort: Double = 0.62
    var size: CGFloat = 140

    var body: some View {
        let outer = size * 0.085
        let inner = size * 0.07
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: outer)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(
                    AngularGradient(colors: [Theme.recovery, Theme.accent, Theme.recovery], center: .center),
                    style: StrokeStyle(lineWidth: outer, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: inner)
                .padding(outer + 4)
            Circle()
                .trim(from: 0, to: effort)
                .stroke(Theme.effort, style: StrokeStyle(lineWidth: inner, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(outer + 4)
            VStack(spacing: 0) {
                Text("\(score)%")
                    .font(Theme.display(size * 0.26))
                Text("READY")
                    .font(.system(size: max(9, size * 0.075), weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Readiness \(score) percent")
    }
}

struct HeartRateLabel: View {
    let bpm: Int?
    var size: CGFloat = 28
    var color: Color = Theme.heart

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.7))
                .foregroundStyle(color)
            Text(bpm.map(String.init) ?? "--")
                .font(Theme.display(size).monospacedDigit())
                .contentTransition(.numericText())
            Text("BPM")
                .font(Theme.display(size * 0.45))
                .foregroundStyle(Theme.secondaryText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bpm.map { "Heart rate \($0) beats per minute" } ?? "Heart rate unavailable")
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Theme.accent)
        .foregroundStyle(Theme.onAccent)
    }
}

extension View {
    /// The rounded dark card used across the iPhone screens.
    func card(padding: CGFloat = 20) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    /// A small uppercase section label, like "PLANNED WORKOUT".
    func sectionLabel(_ color: Color = Theme.accent) -> some View {
        self.font(.footnote.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(color)
    }
}
