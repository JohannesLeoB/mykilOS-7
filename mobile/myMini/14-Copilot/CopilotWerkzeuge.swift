import Foundation

/// Die Werkzeug-Registry des Copiloten: die echten App-Faehigkeiten als
/// Claude-Tools. Jedes Tool liest nur (keine Schreibaktion ohne
/// Bestaetigung — Karte->Bestaetigung gilt auch hier). Der Copilot fasst
/// zusammen, entwirft, rechnet; ausgefuehrt/gespeichert wird weiter ueber
/// die jeweilige View mit Bestaetigung.
@MainActor
struct CopilotWerkzeuge {
    let projectStore: ProjectStore
    let feldFotoStore: FeldFotoStore
    private let abnahme = AbnahmeprotokollStore()
    private let vertraege = VertragsRegister()
    private let partner = ServicePartnerStore()
    private let kontakte = KontakteStore()

    static let definitionen: [CopilotWerkzeugDef] = [
        CopilotWerkzeugDef(
            name: "projekte_suchen",
            beschreibung: "Sucht Projekte nach Name oder Nummer. Gibt Treffer mit Nummer, Titel und Art zurueck.",
            schema: ["type": "object", "properties": ["suche": ["type": "string", "description": "Name oder Nummer, leer = alle"]], "required": []]
        ),
        CopilotWerkzeugDef(
            name: "projekt_details",
            beschreibung: "Liefert alles, was zu einem Projekt lokal erfasst ist: Art, Volumen, letztes Angebot, Warenkorb-Geraete, Anzahl Feld-Fotos/Maengel/Vertraege/Service-Anfragen, Drive-Link.",
            schema: ["type": "object", "properties": ["projektnummer": ["type": "string"]], "required": ["projektnummer"]]
        ),
        CopilotWerkzeugDef(
            name: "firefly_prompt",
            beschreibung: "Baut einen fotorealistischen Firefly-Render-Prompt (englisch) fuer ein Projekt aus Stil und Wuenschen.",
            schema: ["type": "object", "properties": [
                "projektnummer": ["type": "string"],
                "stil": ["type": "string", "description": "z. B. Landhaus, Modern, Skandinavisch"],
                "material": ["type": "string"],
                "elemente": ["type": "string"]
            ], "required": ["projektnummer"]]
        ),
        CopilotWerkzeugDef(
            name: "sonnenstand",
            beschreibung: "Berechnet Sonnenrichtung und -hoehe fuer Breiten-/Laengengrad und Zeitpunkt (ISO, z. B. 2026-07-14T15:00). Fuer Licht-/Fensterplanung.",
            schema: ["type": "object", "properties": [
                "breitengrad": ["type": "number"], "laengengrad": ["type": "number"],
                "zeitpunkt": ["type": "string", "description": "ISO-Datum+Zeit, leer = jetzt"]
            ], "required": ["breitengrad", "laengengrad"]]
        ),
        CopilotWerkzeugDef(
            name: "kontakt_finden",
            beschreibung: "Sucht einen Kunden im Verzeichnis und gibt Telefon, E-Mail und Adresse zurueck.",
            schema: ["type": "object", "properties": ["name": ["type": "string"]], "required": ["name"]]
        ),
    ]

    /// Fuehrt ein Tool aus und gibt das Ergebnis als Text zurueck (geht als
    /// tool_result zurueck an Claude).
    func fuehreAus(name: String, eingabe: [String: Any]) -> String {
        switch name {
        case "projekte_suchen": return projekteSuchen(eingabe["suche"] as? String ?? "")
        case "projekt_details": return projektDetails(eingabe["projektnummer"] as? String ?? "")
        case "firefly_prompt": return fireflyPrompt(eingabe)
        case "sonnenstand": return sonnenstand(eingabe)
        case "kontakt_finden": return kontaktFinden(eingabe["name"] as? String ?? "")
        default: return "Unbekanntes Werkzeug: \(name)"
        }
    }

    private func projekteSuchen(_ suche: String) -> String {
        let treffer = projectStore.matching(suche).sorted { $0.projectNumber > $1.projectNumber }.prefix(15)
        guard !treffer.isEmpty else { return "Keine Projekte gefunden." }
        return treffer.map { "\($0.projectNumber) - \($0.title) (\($0.art ?? $0.kind))" }.joined(separator: "\n")
    }

    private func projekt(_ nummer: String) -> Project? {
        projectStore.projects.first { $0.projectNumber == nummer || $0.title.lowercased() == nummer.lowercased() }
    }

    private func projektDetails(_ nummer: String) -> String {
        guard let p = projekt(nummer) else { return "Projekt \(nummer) nicht gefunden." }
        var z: [String] = ["Projekt \(p.projectNumber) - \(p.title)", "Art: \(p.art ?? p.kind)"]
        if let v = p.volumenText { z.append("Volumen: \(v)") }
        if let a = p.letztesAngebot { z.append("Letztes Angebot: \(a)") }
        if let w = p.warenkorb, !w.isEmpty {
            z.append("Warenkorb: " + w.map(\.name).joined(separator: ", "))
        }
        let fotos = feldFotoStore.fotos.filter { $0.projectNumber == p.projectNumber }.count
        let maengel = abnahme.eintraege.filter { $0.projectNumber == p.projectNumber }.count
        let vertr = vertraege.vertraege.filter { $0.projectNumber == p.projectNumber }.count
        let anfr = partner.anfragen.filter { $0.projectTitel == p.title }.count
        z.append("Erfasst: \(fotos) Feld-Fotos, \(maengel) Maengel, \(vertr) Vertraege, \(anfr) Service-Anfragen")
        if let url = p.driveURL { z.append("Drive: \(url.absoluteString)") }
        return z.joined(separator: "\n")
    }

    private func fireflyPrompt(_ e: [String: Any]) -> String {
        guard let p = projekt(e["projektnummer"] as? String ?? "") else { return "Projekt nicht gefunden." }
        let brief = KreativBrief(
            projectNumber: p.projectNumber, projectTitel: p.title,
            stil: e["stil"] as? String ?? "",
            materialFarbe: e["material"] as? String ?? "",
            elemente: e["elemente"] as? String ?? "")
        return FireflyPromptKomponist.komponiere(brief)
    }

    private func sonnenstand(_ e: [String: Any]) -> String {
        let lat = (e["breitengrad"] as? Double) ?? (e["breitengrad"] as? NSNumber)?.doubleValue ?? 0
        let lon = (e["laengengrad"] as? Double) ?? (e["laengengrad"] as? NSNumber)?.doubleValue ?? 0
        let datum = datumAus(e["zeitpunkt"] as? String)
        let stand = SonnenstandRechner.berechne(datum: datum, breitengrad: lat, laengengrad: lon)
        let auf = SonnenstandRechner.aufUndUntergang(datum: datum, breitengrad: lat, laengengrad: lon)
        let aufT = auf.aufgang?.formatted(date: .omitted, time: .shortened) ?? "-"
        let unterT = auf.untergang?.formatted(date: .omitted, time: .shortened) ?? "-"
        return "Sonne: \(stand.himmelsrichtung) (\(Int(stand.azimut.rounded())) Grad), Hoehe \(Int(stand.hoehe.rounded())) Grad. Aufgang \(aufT), Untergang \(unterT)."
    }

    private func datumAus(_ text: String?) -> Date {
        guard let text, !text.isEmpty else { return Date() }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: text) { return d }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let d = f.date(from: text) { return d }
        f.dateFormat = "yyyy-MM-dd HH:mm"
        if let d = f.date(from: text) { return d }
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: text) ?? Date()
    }

    private func kontaktFinden(_ name: String) -> String {
        let n = name.lowercased()
        guard let k = kontakte.kontakte.first(where: {
            $0.name.lowercased().contains(n) || n.contains($0.name.lowercased())
        }) else { return "Kein Kontakt zu \(name) im Verzeichnis." }
        var z = [k.name]
        if let t = k.telefon { z.append("Tel: \(t)") }
        if let m = k.email { z.append("Mail: \(m)") }
        if let a = k.adresse { z.append("Adresse: \(a)") }
        return z.joined(separator: "\n")
    }
}
