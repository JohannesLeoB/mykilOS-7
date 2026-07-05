import Vision
import UIKit

/// Reiner Textkandidat aus dem Foto — nie automatisch übernommen, immer in
/// der Bestätigungskarte editierbar. Texterkennung ist ein Vorschlag, kein
/// Fakt (Versteh-Kaskade: nie raten, ein Tipp entscheidet).
struct VisitenkartenErkennung {
    var vorname = ""
    var nachname = ""
    var firma = ""
    var telefon = ""
    var email = ""
}

enum VisitenkartenOCR {
    /// On-device Texterkennung (Vision-Framework) — kein API-Key, kein Server.
    static func erkenne(in bild: UIImage) async -> VisitenkartenErkennung {
        guard let cgImage = bild.cgImage else { return VisitenkartenErkennung() }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["de-DE", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil else {
            return VisitenkartenErkennung()
        }

        let zeilen = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }

        var ergebnis = VisitenkartenErkennung()
        for zeile in zeilen where ergebnis.email.isEmpty && zeile.contains("@") {
            ergebnis.email = zeile.trimmingCharacters(in: .whitespaces)
        }
        for zeile in zeilen where ergebnis.telefon.isEmpty && istTelefonAehnlich(zeile) {
            ergebnis.telefon = zeile.trimmingCharacters(in: .whitespaces)
        }
        if let nameZeile = zeilen.first(where: { !$0.contains("@") && !istTelefonAehnlich($0) }) {
            let teile = nameZeile.split(separator: " ", maxSplits: 1)
            ergebnis.vorname = teile.first.map(String.init) ?? ""
            ergebnis.nachname = teile.count > 1 ? String(teile[1]) : ""
        }
        let restZeilen = zeilen.drop(while: { $0 != zeilen.first(where: { !$0.contains("@") && !istTelefonAehnlich($0) }) }).dropFirst()
        if let firmaZeile = restZeilen.first(where: { !$0.contains("@") && !istTelefonAehnlich($0) }) {
            ergebnis.firma = firmaZeile.trimmingCharacters(in: .whitespaces)
        }
        return ergebnis
    }

    private static func istTelefonAehnlich(_ text: String) -> Bool {
        text.filter(\.isNumber).count >= 6
    }
}
