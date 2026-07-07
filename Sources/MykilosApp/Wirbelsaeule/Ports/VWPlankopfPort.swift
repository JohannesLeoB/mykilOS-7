import Foundation
import MykilosKit

// MARK: - VWPlankopfPort (Wirbelsäule, Johannes-Auftrag 2026-07-07)
//
// Backlog: docs/IDEEN_UND_BACKLOG.md, "Vectorworks-Planköpfe aus Checkout generieren" —
// Port #17 im S10-Blueprint ("CAD-/Zeichnungs-Handoff"), bislang nur benannt, nicht gebaut.
// Johannes' Feldliste (wörtlich, 2026-07-07): Kunde, Projekt, Material, Geräte,
// Ausstattung, Beschläge.
//
// ⚠️ EHRLICHE SCOPE-GRENZE (nicht verhandelbar, siehe CLAUDE.md "Kein hohles erledigt"):
// Das exakte Vectorworks-Zielformat (Data-Record-Feldnamen? Worksheet-Spalten? reiner
// Text zum manuellen Einfügen?) ist NICHT verifiziert — der im Backlog angekündigte
// Vectorworks-Referenz-Screenshot lag beim Bau dieses Ports noch nicht vor
// (docs/IDEEN_UND_BACKLOG.md, Zeile ~1653). Dieser Port liefert daher bewusst einen
// **strukturierten Text-Entwurf** (kein Vectorworks-natives Binärformat, kein
// Data-Record-XML) — copy-paste-tauglich für Johannes, bis das echte Zielformat
// verifiziert ist. Name + Meldung markieren das durchgehend als "Entwurf".
//
// Gruppierung: Picks werden nach `CatalogMatrix` (kunde/projekt/material) UND — für
// `.artikel`-Picks — zusätzlich nach dem freien `snapshot.attribute["kategorie"]`-Feld
// in Geräte/Ausstattung/Beschläge sortiert. Ein Artikel-Pick OHNE gesetztes "kategorie"-
// Attribut landet ehrlich in "Sonstige Artikel" statt geraten einer der drei Kategorien
// zugeordnet zu werden.
//
// Feld-Vokabular geerdet (2026-07-07, read-only Recherche in Johannes' echter
// Vectorworks-Werkstatt-Ablage, `~/Desktop/Icloud desktop/vectorworks/exporte/`):
// seine ECHTEN Beschläge-/Material-Exporte (`Custom.csv`, „Liste (Beschlaege) -
// US600_1T_EB-2.xlsx“) nutzen die Spalten Projekt-Nr. / Bauvorhaben / Kommission /
// Position / Artikel(-nummer) / Bezeichnung / Lieferant / Menge / Einzelpreis /
// Gesamtpreis. Diese Zeilen-Tabelle übernimmt genau dieses Vokabular, damit der
// Entwurf sich wie sein bestehender Workflow liest — NICHT weil das echte
// Vectorworks-Titelblock-Feldformat damit bestätigt wäre (das bleibt offen, s. u.).
// `.vwx`/`.sta` sind reine Binärdateien ohne extrahierbare Klassen-/Records-Namen
// (keine ZIP-Container) — die Feld-Grundlage kommt daher ausschließlich aus seinen
// bereits existierenden Tabellen-Exporten, nicht aus reverse-engineerten CAD-Dateien.
public struct VWPlankopfPort: CheckoutPort {

    public let id: PortID
    public let name: String

    public init(
        id: PortID = PortID("vw-plankopf"),
        name: String = "Vectorworks-Plankopf (Entwurf)"
    ) {
        self.id = id
        self.name = name
    }

    /// Ein Plankopf kann aus gemischten Körben (Kunde+Projekt+Material+Artikel), aber
    /// auch aus reinen Material- oder Artikel-Körben gespeist werden.
    public func erlaubteInhaltsArten() -> Set<InhaltsArt> {
        [.gemischt, .material, .artikel]
    }

    // MARK: - Vorschau (schreibt/rendert nichts)

    public func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview {
        let gruppen = try await Self.gruppiere(basket.picks)
        var warnungen = [
            "Entwurf: Vectorworks-Zielformat (Data Record/Worksheet-Feldnamen) noch nicht "
            + "verifiziert — reiner Text-Export zum manuellen Einfügen."
        ]
        if basket.picks.isEmpty {
            warnungen.append("Korb ist leer — der Plankopf-Entwurf enthält nur Projekt/Kunde, keine Positionen.")
        }
        let anzahl = basket.picks.count
        let zusammenfassung =
            "Plankopf-Entwurf für Projekt \(basket.projektNummer) mit \(anzahl) Position\(anzahl == 1 ? "" : "en") "
            + "(\(gruppen.nichtLeereSektionen) Sektionen: \(gruppen.sektionsNamen.joined(separator: ", ")))."
        return CheckoutPreview(zusammenfassung: zusammenfassung, warnungen: warnungen)
    }

    // MARK: - Ausführung (liefert Text-Bytes, schreibt NICHTS weg)

    public func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult {
        let gruppen = try await Self.gruppiere(basket.picks)
        let text = Self.render(basket: basket, gruppen: gruppen, ziel: ziel)
        guard let data = text.data(using: .utf8) else {
            return CheckoutResult(erfolg: false, meldung: "Plankopf-Entwurf konnte nicht kodiert werden.")
        }
        return CheckoutResult(
            erfolg: true,
            referenz: basket.id.description,
            meldung: "Plankopf-Entwurf erzeugt (\(data.count) Bytes, Text — Vectorworks-Feldformat noch offen).",
            nutzlast: data
        )
    }

    // MARK: - Gruppierung (rein, testbar)

    struct Gruppen {
        var kunde: [PickSnapshot] = []
        var projekt: [PickSnapshot] = []
        var material: [PickSnapshot] = []
        var geraete: [PickSnapshot] = []
        var ausstattung: [PickSnapshot] = []
        var beschlaege: [PickSnapshot] = []
        var sonstigeArtikel: [PickSnapshot] = []

        var nichtLeereSektionen: Int {
            [kunde, projekt, material, geraete, ausstattung, beschlaege, sonstigeArtikel]
                .filter { $0.isEmpty == false }.count
        }
        var sektionsNamen: [String] {
            var namen: [String] = []
            if kunde.isEmpty == false { namen.append("Kunde") }
            if projekt.isEmpty == false { namen.append("Projekt") }
            if material.isEmpty == false { namen.append("Material") }
            if geraete.isEmpty == false { namen.append("Geräte") }
            if ausstattung.isEmpty == false { namen.append("Ausstattung") }
            if beschlaege.isEmpty == false { namen.append("Beschläge") }
            if sonstigeArtikel.isEmpty == false { namen.append("Sonstige Artikel") }
            return namen
        }
    }

    /// Kategorie-Attribut-Schlüssel für Artikel-Picks (Johannes-Feldliste): "geraet"/
    /// "ausstattung"/"beschlag" — case-insensitiv, sonst "Sonstige Artikel".
    static func gruppiere(_ picks: [any Pick]) async throws -> Gruppen {
        var gruppen = Gruppen()
        for pick in picks {
            _ = try await pick.resolve()   // Rückverfolgbarkeit/Materialisierung wie DokumentPort
            let snapshot = pick.snapshot
            switch pick.matrix {
            case .kunde:
                gruppen.kunde.append(snapshot)
            case .projekt:
                gruppen.projekt.append(snapshot)
            case .material:
                gruppen.material.append(snapshot)
            case .artikel:
                switch snapshot.attribute["kategorie"]?.lowercased() {
                case "geraet", "gerät": gruppen.geraete.append(snapshot)
                case "ausstattung": gruppen.ausstattung.append(snapshot)
                case "beschlag", "beschläge": gruppen.beschlaege.append(snapshot)
                default: gruppen.sonstigeArtikel.append(snapshot)
                }
            default:
                gruppen.sonstigeArtikel.append(snapshot)
            }
        }
        return gruppen
    }

    // MARK: - Text-Rendering (rein, testbar)

    /// Kopfzeilen-Felder aus Johannes' echten Beschläge-/Material-Exporten: Projekt-Nr.
    /// (immer aus `basket.projektNummer`), Bauvorhaben/Kommission optional aus `ziel.parameter`
    /// (kein Fantasiewert, wenn nicht mitgegeben — bleiben dann schlicht weg), Datum = Erzeugungs-
    /// zeitpunkt des Entwurfs (deutsches Format `dd.MM.yy`, wie in seinen echten Exporten gesehen).
    static func render(basket: WorkBasket, gruppen: Gruppen, ziel: PortZiel, jetzt: Date = Date()) -> String {
        var lines: [String] = [
            "PLANKOPF-ENTWURF (Vectorworks-Feldformat noch nicht verifiziert)",
            "Projekt-Nr.: \(basket.projektNummer)"
        ]
        if let bauvorhaben = ziel.parameter["bauvorhaben"], bauvorhaben.isEmpty == false {
            lines.append("Bauvorhaben: \(bauvorhaben)")
        }
        if let kommission = ziel.parameter["kommission"], kommission.isEmpty == false {
            lines.append("Kommission: \(kommission)")
        }
        lines.append("Datum: \(Self.datumsFormat.string(from: jetzt))")
        lines.append("")

        appendSection(&lines, titel: "KUNDE", items: gruppen.kunde)
        appendSection(&lines, titel: "PROJEKT", items: gruppen.projekt)
        appendSection(&lines, titel: "MATERIAL", items: gruppen.material)
        appendTabelle(&lines, titel: "GERÄTE", items: gruppen.geraete)
        appendTabelle(&lines, titel: "AUSSTATTUNG", items: gruppen.ausstattung)
        appendTabelle(&lines, titel: "BESCHLÄGE", items: gruppen.beschlaege)
        appendTabelle(&lines, titel: "SONSTIGE ARTIKEL", items: gruppen.sonstigeArtikel)
        return lines.joined(separator: "\n")
    }

    private static let datumsFormat: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yy"; fmt.locale = Locale(identifier: "de_DE"); return fmt
    }()

    private static func appendSection(_ lines: inout [String], titel: String, items: [PickSnapshot]) {
        guard items.isEmpty == false else { return }
        lines.append("\(titel):")
        for item in items {
            let mengeSuffix = item.menge > 1 ? " ×\(item.menge)" : ""
            lines.append("  - \(item.bezeichnung)\(mengeSuffix)")
        }
        lines.append("")
    }

    /// Tabellenzeilen für Artikel-Sektionen (Geräte/Ausstattung/Beschläge/Sonstige) im
    /// Spalten-Vokabular seiner echten Häfele-Beschläge-Exporte: Position | Artikel | Bezeichnung |
    /// Lieferant | Menge | Einzelpreis | Gesamtpreis. `Artikel`/`Lieferant` kommen aus den freien
    /// `snapshot.attribute`-Feldern ("artikelnummer"/"lieferant") — fehlen sie, steht ehrlich „—“
    /// statt eines erfundenen Werts.
    private static func appendTabelle(_ lines: inout [String], titel: String, items: [PickSnapshot]) {
        guard items.isEmpty == false else { return }
        lines.append("\(titel):")
        lines.append("  Pos. | Artikel | Bezeichnung | Lieferant | Menge | Einzelpreis | Gesamtpreis")
        for (index, item) in items.enumerated() {
            let artikel = item.attribute["artikelnummer"] ?? "—"
            let lieferant = item.attribute["lieferant"] ?? "—"
            let einzelpreis = item.vkEinzel.map(euro) ?? "—"
            let gesamtpreis = item.vkEinzel.map { euro($0 * Double(item.menge)) } ?? "—"
            lines.append(
                "  \(index + 1) | \(artikel) | \(item.bezeichnung) | \(lieferant) | "
                + "\(item.menge) | \(einzelpreis) | \(gesamtpreis)"
            )
        }
        lines.append("")
    }

    private static func euro(_ wert: Double) -> String {
        String(format: "%.2f €", wert)
    }
}
