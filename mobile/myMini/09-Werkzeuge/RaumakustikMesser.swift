import AVFoundation

/// Raumakustik-Check (#49, bewusst verkleinert): eine echte Nachhallzeit-
/// Messung bräuchte einen kontrollierten Sweep-Ton + Schallpegel-Analyse,
/// die ohne kalibriertes Mikrofon nicht verlässlich ist — genau die
/// Ehrlichkeitsgrenze, die schon Beleuchtungs-Check und Farbtemperatur-Check
/// ziehen. Dieser Baustein misst stattdessen die grobe Umgebungslautstärke
/// über wenige Sekunden — ein Vor-Ort-Anhaltspunkt, kein Schallpegelmesser.
enum Raumklangniveau: String {
    case ruhig = "Ruhig"
    case normal = "Normal"
    case laut = "Laut"

    var empfehlung: String {
        switch self {
        case .ruhig:
            return "Ruhige Umgebung — für Kundengespräche und Aufnahmen gut geeignet."
        case .normal:
            return "Normale Umgebungslautstärke — für die meisten Zwecke unauffällig."
        case .laut:
            return "Laute Umgebung — Trittschall/Akustikdecken-Themen hier eher relevant, echte Messung bräuchte ein kalibriertes Gerät."
        }
    }

    var systemImage: String {
        switch self {
        case .ruhig: return "speaker.slash.fill"
        case .normal: return "speaker.wave.1.fill"
        case .laut: return "speaker.wave.3.fill"
        }
    }
}

enum RaumakustikFehler: Error, LocalizedError {
    case keineBerechtigung
    case aufnahmeFehlgeschlagen(String)

    var errorDescription: String? {
        switch self {
        case .keineBerechtigung: return "Keine Berechtigung fürs Mikrofon erteilt."
        case .aufnahmeFehlgeschlagen(let text): return "Messung fehlgeschlagen: \(text)"
        }
    }
}

/// Kein `SpracheZuTextService`-Doppelbau: dieser Messer erkennt keinen Text,
/// er liest nur den Pegel — daher eigener, schlankerer `AVAudioRecorder`
/// statt Speech-Framework.
@MainActor
final class RaumakustikMesser {
    func berechtigungAnfragen() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Misst `dauer` Sekunden lang die Durchschnittslautstärke und
    /// kategorisiert grob. Kein Textinhalt wird verarbeitet oder gespeichert.
    func messen(dauer: TimeInterval = 3.0) async throws -> Raumklangniveau {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw RaumakustikFehler.aufnahmeFehlgeschlagen(error.localizedDescription)
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).caf")
        let einstellungen: [String: Any] = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1
        ]

        let recorder: AVAudioRecorder
        do {
            recorder = try AVAudioRecorder(url: tempURL, settings: einstellungen)
        } catch {
            throw RaumakustikFehler.aufnahmeFehlgeschlagen(error.localizedDescription)
        }
        recorder.isMeteringEnabled = true
        recorder.record()
        defer {
            recorder.stop()
            try? FileManager.default.removeItem(at: tempURL)
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }

        var messwerte: [Float] = []
        let schritte = Int(dauer / 0.2)
        for _ in 0..<max(schritte, 1) {
            try await Task.sleep(for: .seconds(0.2))
            recorder.updateMeters()
            messwerte.append(recorder.averagePower(forChannel: 0))
        }

        let mittelwert = messwerte.isEmpty ? -60 : messwerte.reduce(0, +) / Float(messwerte.count)

        switch mittelwert {
        case ..<(-40): return .ruhig
        case ..<(-20): return .normal
        default: return .laut
        }
    }
}
