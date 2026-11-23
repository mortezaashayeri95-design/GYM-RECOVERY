import SwiftUI

@main
struct GymRecoveryWatchApp: App {
    @State private var profile = UserProfile()

    var body: some Scene {
        WindowGroup {
            WatchRootView(profile: profile)
        }
    }
}

/// Swipe up and down between the workout, readiness and milestones pages.
struct WatchRootView: View {
    @State private var controller: WorkoutController

    init(profile: UserProfile) {
        _controller = State(initialValue: WorkoutController(profile: profile))
    }

    var body: some View {
        TabView {
            WorkoutFlowView(controller: controller)
            WatchInsightView()
            WatchMilestonesView()
        }
        .tabViewStyle(.verticalPage)
    }
}
