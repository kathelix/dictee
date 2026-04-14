import AVFoundation
import Observation

@Observable
final class SpeechService {
    var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: SpeechDelegate?

    init() {
        let d = SpeechDelegate(service: self)
        delegate = d
        synthesizer.delegate = d
        configureAudioSession()
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = 0.42        // slightly slower than default for dictation
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: .duckOthers
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}

// Separate delegate object to avoid @MainActor isolation issues with
// AVSpeechSynthesizerDelegate callbacks that arrive on background threads.
private final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var service: SpeechService?

    init(service: SpeechService) {
        self.service = service
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in service?.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in service?.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in service?.isSpeaking = false }
    }
}
