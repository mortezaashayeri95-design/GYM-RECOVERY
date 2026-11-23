import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// The recovery coach agent. It answers with Apple's on-device language model when the
/// device supports it (iOS 26 with Apple Intelligence on), and with simple rules otherwise.
/// The safety check always runs first.
@MainActor
final class CoachAgent {
    private let lastWorkout: WorkoutLog
    private let profile: UserProfile
    /// Holds a `LanguageModelSession` so the coach remembers the conversation.
    /// Typed as `Any` because the type only exists on iOS 26 and later.
    private var modelSession: Any?

    init(lastWorkout: WorkoutLog, profile: UserProfile) {
        self.lastWorkout = lastWorkout
        self.profile = profile
    }

    /// True when replies come from the on-device language model.
    var usesLanguageModel: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            return true
        }
        #endif
        return false
    }

    func reply(to question: String) async -> String {
        if let safety = safetyReply(to: question) {
            return safety
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), usesLanguageModel {
            do {
                let session = languageModelSession()
                let response = try await session.respond(to: question)
                return response.content
            } catch {
                // Fall back to the rules below, for example if the model is busy or the question is refused.
            }
        }
        #endif
        return ruleBasedReply(to: question)
    }

    // MARK: - Safety

    private func safetyReply(to question: String) -> String? {
        let text = question.lowercased()
        guard ["pain", "hurt", "dizzy", "injur", "chest", "faint", "breath"].contains(where: text.contains) else {
            return nil
        }
        return "Stop training if you feel pain, dizziness, chest discomfort or shortness of breath, and speak to a doctor or physiotherapist. I can only give general training guidance."
    }

    // MARK: - Language model

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func languageModelSession() -> LanguageModelSession {
        if let session = modelSession as? LanguageModelSession {
            return session
        }
        let session = LanguageModelSession(instructions: instructions)
        modelSession = session
        return session
    }
    #endif

    private var instructions: String {
        let goal = profile.goal
        let peak = Int(Double(RecoveryEngine.estimatedMaxHeartRate(age: profile.age)) * RecoveryEngine.highPeakShare)
        let rests = lastWorkout.rests
            .map { "\($0.exerciseName): rested \(RecoveryEngine.format($0.restSeconds)), suggested \(RecoveryEngine.format($0.suggestedSeconds))" }
            .joined(separator: "; ")
        return """
        You are the voice coach in Gym Recovery, an app that guides rest between sets in the gym.
        Your replies are read aloud, so answer in at most three short, plain sentences with no lists, symbols or markdown.
        Only give general guidance about rest between sets, recovery and workout structure.
        Never give medical advice. If the person mentions pain, injury, dizziness or feeling unwell, tell them to stop and see a professional.
        If you don't know something, say so. Do not invent numbers that are not given here.

        How the app sets rest:
        - Goal: \(goal.title). Big lifts start at \(RecoveryEngine.format(RecoveryEngine.bigLiftRest(goal: goal))), isolation lifts at \(RecoveryEngine.format(RecoveryEngine.isolationRest(goal: goal))).
        - After a set rated 4 out of 5, rest grows by 15%. After 5 out of 5, by 25%. After 1 or 2, it shrinks by 15%.
        - If heart rate at the end of a set reaches \(peak) bpm or more, 20 seconds are added.
        - The person can add 15 seconds or skip rest at any time.

        The person: age \(profile.age), resting heart rate \(profile.restingHeartRate) bpm.
        Last workout, \(lastWorkout.name): \(rests).
        """
    }

    // MARK: - Rules fallback

    private func ruleBasedReply(to question: String) -> String {
        let text = question.lowercased()
        if text.contains("recover") || text.contains("today") || text.contains("how did i") {
            let onTarget = lastWorkout.rests.filter { !$0.isTooShort }
            let tooShort = lastWorkout.rests.filter(\.isTooShort).map(\.exerciseName)
            var answer = "In \(lastWorkout.name) your rest was on target for \(onTarget.count) of \(lastWorkout.rests.count) exercises."
            if !tooShort.isEmpty {
                answer += " You rested less than suggested on \(tooShort.joined(separator: " and ")), so try waiting for the tap next time."
            }
            return answer
        }
        if text.contains("less") || text.contains("skip") || text.contains("shorter") {
            return "Yes. Tap Skip anytime. If you often skip, rate your sets honestly so the suggestions match how you feel."
        }
        if text.contains("why") || text.contains("longer") || text.contains("more rest") {
            return "I add rest when you rate a set 4 or 5 out of 5, or when your heart rate peaks high during the set. That gives you time to recover before the next one."
        }
        if text.contains("goal") {
            return "Your \(profile.goal.title.lowercased()) goal sets your starting rest: \(RecoveryEngine.format(RecoveryEngine.bigLiftRest(goal: profile.goal))) for big lifts and \(RecoveryEngine.format(RecoveryEngine.isolationRest(goal: profile.goal))) for isolation lifts. Then I adjust it after each set."
        }
        return "I can explain your rest times, how you recovered, and how your goal changes your rest. Try asking why your rest was longer."
    }
}
