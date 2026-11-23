import SwiftUI

enum AppTab: Hashable {
    case today, workout, progress, coach, profile
}

/// State shared by every iPhone screen.
@MainActor
@Observable
final class AppModel {
    let profile: UserProfile
    let workout: WorkoutController
    var selectedTab: AppTab = .today

    init() {
        let profile = UserProfile()
        self.profile = profile
        workout = WorkoutController(profile: profile)
    }

    func startWorkout() {
        workout.start()
        selectedTab = .workout
    }
}

@main
struct GymRecoveryApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "house") }
                .tag(AppTab.today)
            PhoneWorkoutView()
                .tabItem { Label("Workout", systemImage: "dumbbell") }
                .tag(AppTab.workout)
            InsightsView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(AppTab.progress)
            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left") }
                .tag(AppTab.coach)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(AppTab.profile)
        }
    }
}
