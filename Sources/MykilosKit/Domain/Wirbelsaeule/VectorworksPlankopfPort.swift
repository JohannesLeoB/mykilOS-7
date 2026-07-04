import Foundation

// MARK: - VectorworksPlankopfPort (Port #17, v1 — „ausgestreckte Hand")
//
// CheckoutPort für die Vectorworks-Plankopf-Befüllung (Title-Block) per
// DATEI-AUSGABE (Entscheidung 2026-07-04: nicht Sync — VW ist von außen nicht
// beschreibbar; jede Automatisierung liest am Ende eine Datei).
//
// SCOPE-GRENZE v1 (bewusst, Johannes 2026-07-04: „Hand ausstrecken, aber
// entspannt warten"):
//   - I/O hier DEFINIERT, aber NICHT nach außen verdrahtet: keine Registrierung
//     in einer PortRegistry, keine UI, KEIN Write in die `mykilOS_CAD Adapter`-
//     Postbox. `execute()` liefert die TSV-Bytes als `CheckoutResult.nutzlast`.
//   - Wie Vectorworks die Datei später holt (TitleBlockManager-Import oder
//     VW-internes Skript), wird separat komponiert — gleicher Datei-Vertrag.
//   - Kein AppKit/PDFKit nötig → lebt Foundation-only in MykilosKit (anders als
//     DokumentPort, der wegen MykPDFRenderer auf App-Ebene wohnt).
//
// AUSGABEFORMAT: Tab-getrennte Schlüssel→Wert-Zeilen (TSV; robust gegen Kommas
// in Adressen, vom VW-Plankopf-Manager les-/importierbar), UTF-8. Kopfzeilen =
// Plankopf-Felder (Mapping aus dem echten MYKILOS-Titelblock destilliert,
// Screenshots 2026-07-04); danach optional Geräte-/Material-Zeilen aus den
// Basket-Picks (v1.5) — bewusst OHNE Preise: ein CAD-Plan ist kein Preisdokument.
public struct VectorworksPlankopfPort: CheckoutPort {

    public let id: PortID
    public let name: String

    public init(id: PortID = PortID("vectorworks-plankopf"),
                name: String = "Vectorworks Plankopf (Datei)") {
        self.id = id
        self.name = name
    }

    /// Plankopf ist Dokument-Ausgabe; Geräte-Blöcke machen Artikel-Körbe gültig.
    public func erlaubteInhaltsArten() -> Set<InhaltsArt> {
        [.dokumente, .artikel]
    }

    // MARK: - I/O-Vertrag (die Adapter-Tabelle in Code-Form)

    /// Plankopf-Felder in AUSGABE-Reihenfolge. Quelle-Mapping (mykilOS → Plankopf):
    /// Kunde→customerName · Raum/Typ→project.kind · Adresse→customer.street ·
    /// PLZ/Ort→zip+city · Kundennr.→customerNumber · Datum→Projekt/Heute ·
    /// Projektnummer→projectNumber · Zeichnung→User-Kürzel. Maßstab/Format bleiben
    /// CAD-seitig; der Firmen-Footer ist konstant.
    public static let headerFelder: [String] = [
        "KUNDE", "RAUM_TYP", "ADRESSE", "PLZ_ORT",
        "KUNDEN_NR", "DATUM", "PROJEKT_NR", "ZEICHNUNG",
    ]

    /// Konstanter Firmen-Footer des Titelblocks.
    public static let footerKonstanten: [(schluessel: String, wert: String)] = [
        ("FIRMA", "MYKILOS GmbH"),
        ("FIRMA_MAIL", "hello@mykilos.de"),
        ("FIRMA_WEB", "www.mykilos.de"),
    ]

    /// Erwartete `PortZiel`-Form: `kind == "cad-plankopf"`, `parameter`-Schlüssel =
    /// `headerFelder` (kleingeschrieben). Der WorkBasket trägt keine Kunden-
    /// Metadaten — die Header-Werte kommen deshalb über das Ziel.
    public static let zielKind = "cad-plankopf"

    // MARK: - Vorschau (schreibt nichts)

    public func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview {
        let fehlend = Self.fehlendePflichtfelder(in: ziel)
        var warnungen: [String] = []
        if fehlend.isEmpty == false {
            warnungen.append("Plankopf-Felder fehlen: \(fehlend.joined(separator: ", ")).")
        }
        if ziel.kind != Self.zielKind {
            warnungen.append("Ziel-Art ist „\(ziel.kind)“ — erwartet „\(Self.zielKind)“.")
        }
        let geraete = basket.picks.count
        let zusammenfassung = "Plankopf-Datei (TSV) mit \(Self.headerFelder.count) Kopffeldern"
            + (geraete > 0 ? " + \(geraete) Geräte-/Material-Zeile\(geraete == 1 ? "" : "n")." : ".")
        return CheckoutPreview(zusammenfassung: zusammenfassung, warnungen: warnungen)
    }

    // MARK: - Ausführung (baut TSV-Bytes, schreibt NICHTS weg)

    public func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult {
        var zeilen: [String] = []
        // Kopfblock: Feld → Wert (fehlende Werte leer, damit der Import stabil bleibt).
        for feld in Self.headerFelder {
            let wert = ziel.parameter[feld.lowercased()] ?? ""
            zeilen.append("\(feld)\t\(Self.bereinigt(wert))")
        }
        for konstante in Self.footerKonstanten {
            zeilen.append("\(konstante.schluessel)\t\(konstante.wert)")
        }
        // v1.5: Geräte-/Material-Block aus den Picks — Bezeichnung + Menge, KEINE Preise.
        for pick in basket.picks {
            let s = pick.snapshot
            zeilen.append("GERAET\t\(Self.bereinigt(s.bezeichnung))\t\(s.menge)")
        }
        let tsv = zeilen.joined(separator: "\n") + "\n"
        return CheckoutResult(
            erfolg: true,
            referenz: nil,   // bewusst: noch keine Postbox-Ablage (v1-Scope-Grenze)
            meldung: "Plankopf-TSV erzeugt (\(zeilen.count) Zeilen) — Ablage in die "
                + "mykilOS_CAD-Adapter-Postbox folgt in einem späteren, separaten Schritt.",
            nutzlast: Data(tsv.utf8))
    }

    // MARK: - Helfer (rein)

    /// Pflichtfelder für einen brauchbaren Plankopf: Kunde + Projektnummer.
    static func fehlendePflichtfelder(in ziel: PortZiel) -> [String] {
        ["kunde", "projekt_nr"].filter { key in
            (ziel.parameter[key] ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        }.map { $0.uppercased() }
    }

    /// TSV-sicher: Tabs/Zeilenumbrüche im Wert werden zu Leerzeichen.
    static func bereinigt(_ wert: String) -> String {
        wert.replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}
