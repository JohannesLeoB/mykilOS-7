import AVFoundation
import Observation

/// Morgen-Brief gesprochen: ★2+★4 über Ohren statt Screen. Reine
/// Sprachausgabe (Text-to-Speech) — kein Mikrofon, keine Aufnahme, daher
/// auch keine neue Info.plist-Berechtigung nötig (anders als
/// `SpracheZuTextService`, das Spracheingabe erkennt).
@MainActor
@Observable
final class MorgenBriefSprecher: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var sprichtGerade = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func sprich(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        sprichtGerade = true
        synthesizer.speak(utterance)
    }

    func stoppen() {
        synthesizer.stopSpeaking(at: .immediate)
        sprichtGerade = false
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in sprichtGerade = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in sprichtGerade = false }
    }
}
