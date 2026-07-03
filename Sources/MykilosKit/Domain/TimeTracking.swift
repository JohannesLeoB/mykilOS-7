import Foundation

// MARK: - Kostenstelle
// mykilOS 8, Block B: eine Kostenstelle = eine Clockodo-LEISTUNG (services_id).
//
// Zwei-Achsen-Modell (2026-07-01, aus echten Clockodo-Screenshots abgeleitet):
//   • Clockodo „Kunde/Projekt" (customers_id) = die PROJEKT-Achse — kommt in
//     mykilOS aus der Projektnummer, NICHT hier abgebildet (Amoulong, Baron-Voght
//     usw. sind KEINE Kostenstellen).
//   • Clockodo „Leistung" (services_id) = die TÄTIGKEITS-Achse — GENAU DAS sind
//     die Kostenstellen. `clockodoServiceID` trägt die echte services_id, sodass
//     der Buchungspfad ohne Fuzzy-Mapping direkt `services_id` setzen kann.
public struct Kostenstelle: Codable, Hashable, Sendable, Identifiable {
    public let id: String     // stabiler Schlüssel (= name)
    public let name: String
    /// Clockodo `services_id`. nil = Leistung existiert in Clockodo, aber ihre ID
    /// wurde noch nicht erfasst → der Buchungspfad überspringt sie bewusst (kein
    /// Raten einer falschen ID in echten Abrechnungsdaten).
    public let clockodoServiceID: Int?

    public init(id: String? = nil, name: String, clockodoServiceID: Int? = nil) {
        self.id = id ?? name
        self.name = name
        self.clockodoServiceID = clockodoServiceID
    }

    /// Die echten Clockodo-Leistungen der Mykilos GmbH (Stand 2026-07-01, aus den
    /// Clockodo-Screenshots + der Airtable-Tabelle `Clockodo-Leistungen`
    /// tblRtsegocdpM8CJd abgeleitet). Reihenfolge wie im Clockodo-Dropdown
    /// (alphabetisch). Bestellungen/Versand: in Clockodo vorhanden, services_id
    /// hier noch nicht erfasst → nicht buchbar bis ID nachgetragen.
    public static let defaults: [Kostenstelle] = [
        Kostenstelle(name: "Angebotserstellung", clockodoServiceID: 1384970),
        Kostenstelle(name: "Bestellungen"),
        Kostenstelle(name: "Interne Arbeitszeit", clockodoServiceID: 1384967),
        Kostenstelle(name: "Konzeption, Recherche, Planung CAD", clockodoServiceID: 1418402),
        Kostenstelle(name: "Kundenberatung", clockodoServiceID: 1430450),
        Kostenstelle(name: "Ortstermin Baustelle", clockodoServiceID: 1418401),
        Kostenstelle(name: "Projektabrechnung", clockodoServiceID: 1384971),
        Kostenstelle(name: "Projektbesprechung", clockodoServiceID: 1535780),
        Kostenstelle(name: "Projektmanagement", clockodoServiceID: 1384969),
        Kostenstelle(name: "Versand"),
    ]
}

// MARK: - ActiveTimer
// Der EINE aktuell laufende oder pausierte Timer (Single-Instance-Invariante —
// in der App gibt es nie zwei gleichzeitig, erzwungen im TimerStore). Speichert
// nur den aktuellen Laufabschnitt EINER Kostenstelle; ein Kostenstellen- oder
// Projektwechsel schließt diesen Abschnitt als `TimeSegmentDraft` ab und startet
// einen neuen ActiveTimer.
//
// Verstrichene Zeit = pausedAccumulatedSeconds + (isPaused ? 0 : now - runSince).
public struct ActiveTimer: Codable, Equatable, Sendable {
    public var projektNummer: String
    public var projektTitel: String
    public var kostenstelle: String
    /// Beginn des aktuellen, NICHT pausierten Laufabschnitts.
    public var runSince: Date
    /// Summe der Sekunden dieses Abschnitts VOR der aktuellen Pause (bei Resume null bis zur nächsten Pause akkumuliert).
    public var pausedAccumulatedSeconds: Double
    public var isPaused: Bool
    /// Wann dieser Timer-Lauf insgesamt begann (über Pausen/Kostenstellenwechsel hinweg) — für die Segment-Startzeit.
    public var segmentStartedAt: Date

    public init(
        projektNummer: String, projektTitel: String, kostenstelle: String,
        runSince: Date, pausedAccumulatedSeconds: Double = 0, isPaused: Bool = false,
        segmentStartedAt: Date
    ) {
        self.projektNummer = projektNummer
        self.projektTitel = projektTitel
        self.kostenstelle = kostenstelle
        self.runSince = runSince
        self.pausedAccumulatedSeconds = pausedAccumulatedSeconds
        self.isPaused = isPaused
        self.segmentStartedAt = segmentStartedAt
    }

    /// Bisher verstrichene Sekunden dieses Abschnitts, bezogen auf `now`.
    public func elapsedSeconds(now: Date) -> Double {
        pausedAccumulatedSeconds + (isPaused ? 0 : max(0, now.timeIntervalSince(runSince)))
    }
}

// MARK: - TimeSegmentDraft
// Ein abgeschlossener Zeitabschnitt EINES Timer-Laufs, der noch NICHT gebucht ist.
// Entsteht beim Kostenstellen-/Projektwechsel (Zwischenabschnitt) und beim Stopp
// (letzter Abschnitt). Erst die doppelte Buchungs-Bestätigung wandelt alle Drafts
// in gebuchte `TimeSegment`s. So geht beim Kostenstellenwechsel keine Zeit verloren,
// und dennoch wird nichts ohne den zweiten „Ja, buchen"-Schritt committet.
public struct TimeSegmentDraft: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var projektNummer: String
    public var projektTitel: String
    public var kostenstelle: String
    public var startedAt: Date
    public var endedAt: Date
    public var seconds: Double

    public init(
        id: UUID = UUID(), projektNummer: String, projektTitel: String, kostenstelle: String,
        startedAt: Date, endedAt: Date, seconds: Double
    ) {
        self.id = id
        self.projektNummer = projektNummer
        self.projektTitel = projektTitel
        self.kostenstelle = kostenstelle
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.seconds = seconds
    }
}

// MARK: - TimeSegment
// Ein GEBUCHTER Zeitabschnitt (append-only, lokal). Das ist das endgültige Ergebnis
// der doppelten Bestätigung. Externer Upload (Clockodo) ist S3 — hier rein lokal.
public struct TimeSegment: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var projektNummer: String
    public var projektTitel: String
    public var kostenstelle: String
    public var startedAt: Date
    public var endedAt: Date
    public var seconds: Double
    public var bookedAt: Date

    public init(
        id: UUID = UUID(), projektNummer: String, projektTitel: String, kostenstelle: String,
        startedAt: Date, endedAt: Date, seconds: Double, bookedAt: Date = Date()
    ) {
        self.id = id
        self.projektNummer = projektNummer
        self.projektTitel = projektTitel
        self.kostenstelle = kostenstelle
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.seconds = seconds
        self.bookedAt = bookedAt
    }

    public init(fromDraft draft: TimeSegmentDraft, bookedAt: Date = Date()) {
        self.init(
            id: draft.id, projektNummer: draft.projektNummer, projektTitel: draft.projektTitel,
            kostenstelle: draft.kostenstelle, startedAt: draft.startedAt, endedAt: draft.endedAt,
            seconds: draft.seconds, bookedAt: bookedAt)
    }
}

// MARK: - ProjectZielkontingent
// Lokal editierbares Soll-Stunden-Kontingent je Projekt mit Herkunfts-Flag.
// S1: Feldgerüst + lokales Editieren. S2: Auto-Befüllung aus Airtable.
public enum ZielkontingentHerkunft: String, Codable, Sendable {
    case auto       // aus externer Quelle abgeleitet (S2)
    case manuell    // lokal vom Nutzer gesetzt
}

public struct ProjectZielkontingent: Codable, Equatable, Sendable, Identifiable {
    public var id: String { projektNummer }
    public var projektNummer: String
    public var zielStunden: Double
    public var herkunft: ZielkontingentHerkunft
    public var updatedAt: Date

    public init(projektNummer: String, zielStunden: Double, herkunft: ZielkontingentHerkunft = .manuell, updatedAt: Date = Date()) {
        self.projektNummer = projektNummer
        self.zielStunden = zielStunden
        self.herkunft = herkunft
        self.updatedAt = updatedAt
    }
}

// MARK: - TimerFormat
// Reine, testbare Formatierung der Timer-Anzeige (HH:MM:SS und „47 Min").
public enum TimerFormat {
    /// 3725 s → „01:02:05".
    public static func clock(_ seconds: Double) -> String {
        let total = Int(max(0, seconds.rounded()))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// 2820 s → „47 Min" · 4200 s → „1 Std 10 Min" (für Buchungs-Karten).
    public static func human(_ seconds: Double) -> String {
        let totalMin = Int((seconds / 60).rounded())
        if totalMin < 60 { return "\(totalMin) Min" }
        let h = totalMin / 60, m = totalMin % 60
        return m == 0 ? "\(h) Std" : "\(h) Std \(m) Min"
    }
}
