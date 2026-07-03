import Foundation
import MykilosKit

// MARK: - DokumentPort (Wirbelsäule C2, §4 „Erste native Ports")
//
// Erster nativer CheckoutPort: rendert einen WorkBasket (Geräteliste/Briefpapier)
// als A4-PDF im mykilOS-Stil über den bestehenden `MykPDFRenderer`.
//
// SCOPE-GRENZE (C2, siehe HANDOFF_WIRBELSAEULE_C2_CODEX §3):
//   - KEINE UI-Verdrahtung (kein Sheet, kein Menü).
//   - KEIN externer Write (kein Drive-Upload, keine Postbox). `execute()` liefert
//     die PDF-`Data` im `CheckoutResult.nutzlast` zurück; die Ablage ist ein
//     späterer, separater Schritt.
//   - `MykPDFRenderer` ist eine reine Funktion (kein Netz/Keychain) — der Port
//     bleibt damit ebenfalls rein.
//
// Der Port lebt auf App-Ebene, weil er PDFKit/AppKit (via `MykPDFRenderer`) nutzt;
// `MykilosKit` bleibt Foundation-only (§1).
public struct DokumentPort: CheckoutPort {

    public let id: PortID
    public let name: String

    public init(id: PortID = PortID("dokument"), name: String = "Dokument (PDF)") {
        self.id = id
        self.name = name
    }

    /// Geräteliste ist ein Artikel-Export in Dokumentform → beide Inhalts-Arten.
    public func erlaubteInhaltsArten() -> Set<InhaltsArt> {
        [.dokumente, .artikel]
    }

    // MARK: - Vorschau (schreibt/rendert nichts)

    public func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview {
        let anzahl = basket.picks.count
        let titel = Self.titel(fuer: basket, ziel: ziel)
        var warnungen: [String] = []
        if anzahl == 0 {
            warnungen.append("Korb ist leer — das PDF enthält keine Positionen.")
        }
        let zusammenfassung =
            "PDF „\(titel)“ mit \(anzahl) Position\(anzahl == 1 ? "" : "en") (A4, mykilOS-Stil)."
        return CheckoutPreview(zusammenfassung: zusammenfassung, warnungen: warnungen)
    }

    // MARK: - Ausführung (rendert PDF-Data, schreibt NICHTS weg)

    public func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult {
        // Picks materialisieren — resolve() darf werfen (kein stiller try?).
        var zeilen: [[String]] = [["Bezeichnung", "Menge", "EK netto", "VK netto"]]
        var summeEK = 0.0
        var summeVK = 0.0
        for pick in basket.picks {
            _ = try await pick.resolve()   // Rückverfolgbarkeit/Materialisierung; Inhalt selbst hier nicht gebraucht
            let s = pick.snapshot
            let ek = (s.ekEinzel ?? 0) * Double(s.menge)
            let vk = (s.vkEinzel ?? 0) * Double(s.menge)
            summeEK += ek
            summeVK += vk
            zeilen.append([
                s.bezeichnung,
                String(s.menge),
                Self.euro(s.ekEinzel),
                Self.euro(s.vkEinzel),
            ])
        }

        let titel = Self.titel(fuer: basket, ziel: ziel)
        let hatPositionen = basket.picks.isEmpty == false
        let totals: [(label: String, value: String)] = hatPositionen
            ? [
                (label: "Summe EK netto", value: Self.euro(summeEK)),
                (label: "Summe VK netto", value: Self.euro(summeVK)),
              ]
            : []

        let data = MykPDFRenderer.render(
            title: titel,
            subtitle: "Projekt \(basket.projektNummer)",
            sections: [],
            table: hatPositionen ? zeilen : nil,
            totals: totals
        )

        guard data.isEmpty == false else {
            // MykPDFRenderer liefert im Fehlerfall leere Data (Context-Erzeugung
            // fehlgeschlagen). Das ist ein echter Fehler — nicht still schlucken.
            return CheckoutResult(
                erfolg: false,
                meldung: "PDF-Rendering fehlgeschlagen (keine Bytes erzeugt)."
            )
        }

        return CheckoutResult(
            erfolg: true,
            referenz: basket.id.description,
            meldung: "PDF „\(titel)“ gerendert (\(data.count) Bytes).",
            nutzlast: data
        )
    }

    // MARK: - Helfer (rein)

    /// Titel aus dem Ziel-Parameter „titel“ oder Fallback aus dem Projektbezug.
    static func titel(fuer basket: WorkBasket, ziel: PortZiel) -> String {
        if let t = ziel.parameter["titel"], t.isEmpty == false {
            return t
        }
        return "Geräteliste \(basket.projektNummer)"
    }

    static func euro(_ wert: Double?) -> String {
        guard let wert else { return "—" }
        return euro(wert)
    }

    static func euro(_ wert: Double) -> String {
        String(format: "%.2f €", wert)
    }
}
