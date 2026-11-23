import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var profile = model.profile
        NavigationStack {
            Form {
                Section("About you") {
                    TextField("Name", text: $profile.name)
                    Stepper("Age: \(profile.age)", value: $profile.age, in: 14...90)
                    Stepper("Weight: \(profile.weightKg.formatted()) kg", value: $profile.weightKg, in: 35...200, step: 0.5)
                    Stepper("Resting heart rate: \(profile.restingHeartRate) bpm", value: $profile.restingHeartRate, in: 35...110)
                }
                Section("Goal") {
                    Picker("Training goal", selection: $profile.goal) {
                        ForEach(TrainingGoal.allCases) { goal in
                            Text(goal.title).tag(goal)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    LabeledContent("Big lifts, first set", value: RecoveryEngine.format(RecoveryEngine.bigLiftRest(goal: profile.goal)))
                    LabeledContent("Isolation lifts", value: RecoveryEngine.format(RecoveryEngine.isolationRest(goal: profile.goal)))
                    LabeledContent("Extra rest above", value: "\(Int(Double(RecoveryEngine.estimatedMaxHeartRate(age: profile.age)) * RecoveryEngine.highPeakShare)) bpm")
                } header: {
                    Text("Your rest times")
                } footer: {
                    Text("General training guidance, not medical advice. Heart rate limits use a rough estimate based on age.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
