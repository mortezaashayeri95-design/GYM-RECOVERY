import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

/// The voice coach: speak a question, the agent answers, and the answer is read aloud.
/// Typing still works for quiet places.
struct CoachView: View {
    @Environment(AppModel.self) private var model
    @State private var voice = VoiceCoach()
    @State private var agent: CoachAgent?
    @State private var messages = [
        ChatMessage(text: "Hi! Tap the microphone and ask me about your rest times and recovery.", isUser: false),
    ]
    @State private var draft = ""
    private let suggestions = ["How did I recover?", "Why was my rest longer?", "Can I rest less?"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                conversation
                statusLine
                micButton
                suggestionChips
                textInput
                Text("General training guidance, not medical advice. Stop if you feel pain.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 8)
            .background(Theme.background)
            .navigationTitle("Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { settingsMenu }
            }
            .task {
                if agent == nil {
                    agent = CoachAgent(lastWorkout: SampleData.lastWorkout, profile: model.profile)
                }
                voice.onFinalTranscript = { text in send(text) }
            }
            .onDisappear {
                voice.stopListening(submit: false)
                voice.stopSpeaking()
            }
        }
    }

    // MARK: - Pieces

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: messages.count) { _, _ in
                guard let last = messages.last else { return }
                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        Group {
            switch voice.state {
            case .listening:
                Text(voice.transcript.isEmpty ? "Listening…" : voice.transcript)
                    .foregroundStyle(voice.transcript.isEmpty ? Theme.secondaryText : .white)
            case .thinking:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Thinking…")
                }
                .foregroundStyle(Theme.secondaryText)
            case .speaking:
                Button {
                    voice.stopSpeaking()
                } label: {
                    Label("Speaking · tap to stop", systemImage: "speaker.wave.2.fill")
                }
                .foregroundStyle(Theme.accent)
            case .idle:
                if let error = voice.errorMessage {
                    Text(error)
                        .foregroundStyle(Theme.effort)
                } else {
                    Text(voice.isHandsFree ? "Hands-free is on" : "Tap to talk")
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .padding(.horizontal)
        .frame(minHeight: 22)
    }

    private var micButton: some View {
        let listening = voice.state == .listening
        return Button {
            voice.toggleListening()
        } label: {
            Image(systemName: listening ? "stop.fill" : "mic.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 76, height: 76)
                .background(Circle().fill(listening ? Theme.effort : Theme.accent))
                .overlay(
                    Circle()
                        .stroke(Theme.accent.opacity(listening ? 0.5 : 0), lineWidth: 8)
                        .scaleEffect(listening ? 1.25 : 1)
                        .animation(listening ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: listening)
                )
        }
        .buttonStyle(.plain)
        .disabled(voice.state == .thinking)
        .accessibilityLabel(listening ? "Stop listening" : "Talk to the coach")
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) { send(suggestion) }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(.white)
                }
            }
            .padding(.horizontal)
        }
        .disabled(voice.state == .thinking)
    }

    private var textInput: some View {
        HStack {
            TextField("Or type a question", text: $draft)
                .textFieldStyle(.roundedBorder)
                .onSubmit { send(draft) }
            Button {
                send(draft)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || voice.state == .thinking)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal)
    }

    private var settingsMenu: some View {
        @Bindable var voice = voice
        return Menu {
            Toggle("Read replies aloud", isOn: $voice.speaksReplies)
            Toggle("Hands-free conversation", isOn: $voice.isHandsFree)
            if let agent {
                Text(agent.usesLanguageModel ? "Answers: on-device AI" : "Answers: built-in rules")
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .accessibilityLabel("Voice settings")
    }

    // MARK: - Pipeline

    /// Speech (or typed text) → agent → reply shown and spoken.
    private func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, voice.state != .thinking, let agent else { return }
        draft = ""
        messages.append(ChatMessage(text: question, isUser: true))
        voice.beginThinking()
        Task {
            let reply = await agent.reply(to: question)
            messages.append(ChatMessage(text: reply, isUser: false))
            voice.deliver(reply)
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .foregroundStyle(message.isUser ? Theme.onAccent : .primary)
                .background(
                    message.isUser ? Theme.accent : Theme.card,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    CoachView()
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
