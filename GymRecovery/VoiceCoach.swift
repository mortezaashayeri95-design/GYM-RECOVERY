import AVFoundation
import Observation
import Speech

/// The speech parts of the coach: listens (speech to text) and talks back (text to speech).
/// The agent in between lives in `CoachAgent`.
@MainActor
@Observable
final class VoiceCoach: NSObject {
    enum State {
        case idle, listening, thinking, speaking
    }

    private(set) var state: State = .idle
    /// What the person has said so far while listening.
    private(set) var transcript = ""
    private(set) var errorMessage: String?
    /// Speak every coach reply out loud.
    var speaksReplies = true
    /// Start listening again after each spoken reply, for a hands-free conversation.
    var isHandsFree = false
    /// Called with the full sentence once the person stops talking.
    @ObservationIgnored var onFinalTranscript: ((String) -> Void)?

    /// Stop listening after this long without new words.
    private let silenceTimeout: Duration = .seconds(1.6)

    @ObservationIgnored private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var recognitionTask: SFSpeechRecognitionTask?
    @ObservationIgnored private var silenceTask: Task<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Listening

    func toggleListening() {
        if state == .listening {
            stopListening(submit: true)
        } else {
            Task { await startListening() }
        }
    }

    func startListening() async {
        stopSpeaking()
        errorMessage = nil
        guard await requestPermissions() else { return }
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition isn't available right now."
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                // Keeps what the person says on the device.
                request.requiresOnDeviceRecognition = true
            }
            self.request = request

            let input = audioEngine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                request.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()

            transcript = ""
            state = .listening
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let isFinal = result?.isFinal ?? false
                let failed = error != nil
                Task { @MainActor in
                    self?.handleRecognition(text: text, isFinal: isFinal, failed: failed)
                }
            }
        } catch {
            errorMessage = "Couldn't start the microphone."
            stopAudio()
            state = .idle
        }
    }

    func stopListening(submit: Bool) {
        guard state == .listening else { return }
        stopAudio()
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        state = .idle
        if submit, !text.isEmpty {
            onFinalTranscript?(text)
        }
    }

    private func handleRecognition(text: String?, isFinal: Bool, failed: Bool) {
        guard state == .listening else { return }
        if let text, !text.isEmpty {
            transcript = text
            restartSilenceTimer()
        }
        if isFinal || failed {
            stopListening(submit: true)
        }
    }

    private func restartSilenceTimer() {
        silenceTask?.cancel()
        silenceTask = Task { [weak self, silenceTimeout] in
            try? await Task.sleep(for: silenceTimeout)
            guard !Task.isCancelled else { return }
            self?.stopListening(submit: true)
        }
    }

    private func stopAudio() {
        silenceTask?.cancel()
        silenceTask = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
    }

    private func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            errorMessage = "Allow speech recognition in Settings to talk to the coach."
            return false
        }
        guard await AVAudioApplication.requestRecordPermission() else {
            errorMessage = "Allow microphone access in Settings to talk to the coach."
            return false
        }
        return true
    }

    // MARK: - Thinking and speaking

    /// Shows that the agent is working on a reply.
    func beginThinking() {
        state = .thinking
    }

    /// Delivers the agent's reply: speaks it, or goes back to idle.
    func deliver(_ reply: String) {
        guard speaksReplies else {
            state = .idle
            return
        }
        let utterance = AVSpeechUtterance(string: reply)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        state = .speaking
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if state == .speaking {
            state = .idle
        }
    }

    private func didFinishSpeaking() {
        guard state == .speaking else { return }
        state = .idle
        if isHandsFree {
            Task { await startListening() }
        }
    }
}

extension VoiceCoach: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.didFinishSpeaking() }
    }
}
