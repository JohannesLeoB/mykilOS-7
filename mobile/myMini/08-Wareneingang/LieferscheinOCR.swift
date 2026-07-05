import Vision
import UIKit

/// Reiner Textkandidat vom Paketlabel — nie automatisch übernommen, immer
/// in der Bestätigungskarte editierbar. Gleiche Haltung wie
/// `VisitenkartenOCR`: Texterkennung ist ein Vorschlag, kein Fakt.
struct LieferscheinErkennung {
    var trackingNummer = ""
    var absender = ""
}

enum LieferscheinOCR {
    /// On-device Texterkennung (Vision-Framework) — kein API-Key, kein Server.
    static func erkenne(in bild: UIImage) async -> LieferscheinErkennung {
        guard let cgImage = bild.cgImage else { return LieferscheinErkennung() }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["de-DE", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil else {
            return LieferscheinErkennung()
        }

        let zeilen = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }

        var ergebnis = LieferscheinErkennung()
        for zeile in zeilen where ergebnis.trackingNummer.isEmpty && istTrackingAehnlich(zeile) {
            ergebnis.trackingNummer = zeile.trimmingCharacters(in: .whitespaces)
        }
        if let absenderZeile = zeilen.first(where: { !istTrackingAehnlich($0) && !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            ergebnis.absender = absenderZeile.trimmingCharacters(in: .whitespaces)
        }
        return ergebnis
    }

    /// Grobe Heuristik: eine lange, überwiegend alphanumerische Zeile ohne
    /// Leerzeichen ist eher eine Tracking-Nummer als ein Name/Ort.
    private static func istTrackingAehnlich(_ text: String) -> Bool {
        let bereinigt = text.trimmingCharacters(in: .whitespaces)
        guard bereinigt.count >= 10, !bereinigt.contains(" ") else { return false }
        let alphanumerisch = bereinigt.filter { $0.isLetter || $0.isNumber }
        return Double(alphanumerisch.count) / Double(bereinigt.count) > 0.9
    }
}
