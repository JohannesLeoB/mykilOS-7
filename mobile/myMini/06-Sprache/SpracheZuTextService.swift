import Foundation
import Speech
import AVFoundation

enum SpracheFehler: Error, LocalizedError {
    case keineBerechtigung
    case erkennungNichtVerfuegbar

    var errorDescription: String? {
        switch self {
        case .keineBerechtigung: return "Keine Berechtigung für Mikrofon oder Spracherkennung erteilt."
        case .erkennungNichtVerfuegbar: return "Spracherkennung ist gerade nicht verfügbar."
        }
    }
}

/// On-device Spracherkennung, Deutsch — kein Cloud-Anruf, kein API-Key, kein
/// Audio verlässt das Gerät (`requiresOnDeviceRecognition`). Genau das
/// "Sprich oder tippe" aus der Fang-Karte, das bisher nur ein Platzhaltertext
/// war. Nimmt auf, bis `stoppen()` gerufen wird, liefert den finalen Text.
@MainActor
final class SpracheZuTextService {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var live = ""

    func berechtigungenAnfragen() async -> Bool {
        let spracheOK = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard spracheOK else { return false }
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func starten(aktualisierung: @escaping (String) -> Void) throws {
        guard let recognizer, recognizer.isAvailable else {
            throw SpracheFehler.erkennungNichtVerfuegbar
        }
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let neueAnfrage = SFSpeechAudioBufferRecognitionRequest()
        neueAnfrage.shouldReportPartialResults = true
        neueAnfrage.requiresOnDeviceRecognition = true
        request = neueAnfrage
        live = ""

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            neueAnfrage.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: neueAnfrage) { [weak self] result, _ in
            guard let result else { return }
            Task { @MainActor in
                self?.live = result.bestTranscription.formattedString
                aktualisierung(result.bestTranscription.formattedString)
            }
        }
    }

    @discardableResult
    func stoppen() -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        let text = live
        live = ""
        request = nil
        task = nil
        return text
    }
}
