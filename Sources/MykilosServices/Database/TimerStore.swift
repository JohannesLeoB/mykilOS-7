import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - GRDB-Records

private struct ActiveTimerRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "activeTimer" }
    static let singletonID = "singleton"
    var id: String
    var projektNummer: String
    var projektTitel: String
    var kostenstelle: String
    var runSince: Double
    var pausedAccumulatedSeconds: Double
    var isPaused: Bool
    var segmentStartedAt: Double

    init(from t: ActiveTimer) {
        id = Self.singletonID
        projektNummer = t.projektNummer
        projektTitel = t.projektTitel
        kostenstelle = t.kostenstelle
        runSince = t.runSince.timeIntervalSince1970
        pausedAccumulatedSeconds = t.pausedAccumulatedSeconds
        isPaused = t.isPaused
        segmentStartedAt = t.segmentStartedAt.timeIntervalSince1970
    }

    var toDomain: ActiveTimer {
        ActiveTimer(
            projektNummer: projektNummer, projektTitel: projektTitel, kostenstelle: kostenstelle,
            runSince: Date(timeIntervalSince1970: runSince),
            pausedAccumulatedSeconds: pausedAccumulatedSeconds, isPaused: isPaused,
            segmentStartedAt: Date(timeIntervalSince1970: segmentStartedAt))
    }
}

private struct TimeSegmentDraftRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "timeSegmentDrafts" }
    var id: String
    var projektNummer: String
    var projektTitel: String
    var kostenstelle: String
    var startedAt: Double
    var endedAt: Double
    var seconds: Double

    init(from d: TimeSegmentDraft) {
        id = d.id.uuidString
        projektNummer = d.projektNummer
        projektTitel = d.projektTitel
        kostenstelle = d.kostenstelle
        startedAt = d.startedAt.timeIntervalSince1970
        endedAt = d.endedAt.timeIntervalSince1970
        seconds = d.seconds
    }

    var toDomain: TimeSegmentDraft? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return TimeSegmentDraft(
            id: uuid, projektNummer: projektNummer, projektTitel: projektTitel, kostenstelle: kostenstelle,
            startedAt: Date(timeIntervalSince1970: startedAt), endedAt: Date(timeIntervalSince1970: endedAt),
            seconds: seconds)
    }
}

private struct TimeSegmentRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "timeSegments" }
    var id: String
    var projektNummer: String
    var projektTitel: String
    var kostenstelle: String
    var startedAt: Double
    var endedAt: Double
    var seconds: Double
    var bookedAt: Double

    init(from s: TimeSegment) {
        id = s.id.uuidString
        projektNummer = s.projektNummer
        projektTitel = s.projektTitel
        kostenstelle = s.kostenstelle
        startedAt = s.startedAt.timeIntervalSince1970
        endedAt = s.endedAt.timeIntervalSince1970
        seconds = s.seconds
        bookedAt = s.bookedAt.timeIntervalSince1970
    }

    var toDomain: TimeSegment? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return TimeSegment(
            id: uuid, projektNummer: projektNummer, projektTitel: projektTitel, kostenstelle: kostenstelle,
            startedAt: Date(timeIntervalSince1970: startedAt), endedAt: Date(timeIntervalSince1970: endedAt),
            seconds: seconds, bookedAt: Date(timeIntervalSince1970: bookedAt))
    }
}

private struct ZielkontingentRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "projectZielkontingente" }
    var projektNummer: String
    var zielStunden: Double
    var herkunft: String
    var updatedAt: Double

    init(from z: ProjectZielkontingent) {
        projektNummer = z.projektNummer
        zielStunden = z.zielStunden
        herkunft = z.herkunft.rawValue
        updatedAt = z.updatedAt.timeIntervalSince1970
    }

    var toDomain: ProjectZielkontingent? {
        guard let h = ZielkontingentHerkunft(rawValue: herkunft) else { return nil }
        return ProjectZielkontingent(
            projektNummer: projektNummer, zielStunden: zielStunden, herkunft: h,
            updatedAt: Date(timeIntervalSince1970: updatedAt))
    }
}

private struct AppSettingRow: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "appSettings" }
    var key: String
    var value: String
    var updatedAt: Double
}

// MARK: - PendingTakeover
public struct PendingTakeover: Equatable, Sendable {
    public let laufendesProjekt: String
    public let laufendeKostenstelle: String
    public let laufendeSekunden: Double
    public let neuesProjektNummer: String
    public let neuesProjektTitel: String
    public let neueKostenstelle: String
}

// MARK: - TimerStore
// mykilOS 8, Block B (S1): das gesamte lokale Zeit-Subsystem. Single-Instance-Invariante,
// Pause/Stopp, Kostenstellen-/Projektwechsel ohne Zeitverlust, doppelte Buchungs-Bestätigung,
// Puls-Erinnerung. KEIN externer Write — alles GRDB-lokal. Externer Upload (Clockodo) ist S3.
//
// Zustandsmaschine (UI liest diese @Observable-Felder):
//   active != nil                         → ein Timer läuft/pausiert (Pille sichtbar).
//   active == nil && !pendingDrafts.empty → Stopp erfolgt, Buchungs-Bestätigung offen.
//   pendingTakeover != nil                → Start während laufendem Timer (Übernahme-Karte).
@MainActor
@Observable
public final class TimerStore {
    public private(set) var active: ActiveTimer?
    public private(set) var pendingDrafts: [TimeSegmentDraft] = []
    public private(set) var pendingTakeover: PendingTakeover?
    public private(set) var bookedSegments: [TimeSegment] = []
    public private(set) var zielkontingente: [String: ProjectZielkontingent] = [:]
    public private(set) var pulseIntervalMinutes: Int = 60
    /// Referenzpunkt für die Puls-Erinnerung. Gesetzt bei Start + Check-in „Läuft weiter".
    public private(set) var reminderAnchor: Date?
    public private(set) var saveState: SaveState = .idle

    // Vorgemerkter Start, der nach Klärung der offenen Buchung ausgeführt wird (Übernahme).
    private var queuedStart: (projektNummer: String, projektTitel: String, kostenstelle: String)?

    private let db: GRDBDatabase
    private let now: @MainActor () -> Date
    // Namespaced, damit der generische appSettings-Store keine Schlüssel-Kollision
    // mit anderen Komponenten (z. B. Block A `provisioningMode`) riskiert.
    private static let pulseIntervalKey = "blockB.timer.pulseIntervalMinutes"

    /// `now` injizierbar für deterministische Tests.
    public init(db: GRDBDatabase, now: @escaping @MainActor () -> Date = { Date() }) {
        self.db = db
        self.now = now
    }

    // MARK: Laden

    public func load() throws {
        active = try db.read { try ActiveTimerRecord.fetchOne($0) }?.toDomain
        pendingDrafts = (try db.read { try TimeSegmentDraftRecord.order(Column("startedAt")).fetchAll($0) })
            .compactMap(\.toDomain)
        bookedSegments = (try db.read { try TimeSegmentRecord.order(Column("bookedAt").desc).fetchAll($0) })
            .compactMap(\.toDomain)
        let ziele = (try db.read { try ZielkontingentRecord.fetchAll($0) }).compactMap(\.toDomain)
        zielkontingente = Dictionary(uniqueKeysWithValues: ziele.map { ($0.projektNummer, $0) })
        if let row = try db.read({ try AppSettingRow.fetchOne($0, key: Self.pulseIntervalKey) }),
           let minutes = Int(row.value), minutes > 0 {
            pulseIntervalMinutes = minutes
        }
        // Nach Neustart mit laufendem Timer: Erinnerungs-Uhr ab jetzt (wir kennen den
        // alten Anchor nicht; konservativ neu ankern, damit es nicht sofort pulst).
        if active != nil { reminderAnchor = now() }
    }

    // MARK: Verstrichene Zeit (für UI-Ticker)

    public func elapsedSeconds() -> Double {
        active?.elapsedSeconds(now: now()) ?? 0
    }

    /// Summe aller Sekunden des aktuellen Laufs (laufender Abschnitt + bereits
    /// abgeschlossene Draft-Abschnitte desselben Laufs).
    public func currentRunSeconds() -> Double {
        let draftSum = pendingDrafts.reduce(0) { $0 + $1.seconds }
        return draftSum + elapsedSeconds()
    }

    // MARK: Start / Übernahme

    /// Startet einen Timer. Läuft bereits ein anderer (anderes Projekt ODER andere
    /// Kostenstelle), wird NICHT sofort gewechselt — `pendingTakeover` wird gesetzt
    /// (UI fragt nach). Gleicher Timer → no-op. Offene Buchung → ignoriert (erst klären).
    public func start(projektNummer: String, projektTitel: String, kostenstelle: String) throws {
        // Offene Buchung blockiert einen neuen Start (Vermischung vermeiden).
        guard pendingDrafts.isEmpty else { return }

        if let active {
            if active.projektNummer == projektNummer && active.kostenstelle == kostenstelle {
                return   // läuft bereits exakt so
            }
            pendingTakeover = PendingTakeover(
                laufendesProjekt: active.projektTitel,
                laufendeKostenstelle: active.kostenstelle,
                laufendeSekunden: currentRunSeconds(),
                neuesProjektNummer: projektNummer,
                neuesProjektTitel: projektTitel,
                neueKostenstelle: kostenstelle)
            return
        }
        try startFresh(projektNummer: projektNummer, projektTitel: projektTitel, kostenstelle: kostenstelle)
    }

    private func startFresh(projektNummer: String, projektTitel: String, kostenstelle: String) throws {
        let t = now()
        let timer = ActiveTimer(
            projektNummer: projektNummer, projektTitel: projektTitel, kostenstelle: kostenstelle,
            runSince: t, pausedAccumulatedSeconds: 0, isPaused: false, segmentStartedAt: t)
        try persistActive(timer)
        active = timer
        reminderAnchor = t
    }

    /// „Übernehmen": laufenden Timer stoppen (→ Buchungs-Bestätigung für das alte
    /// Projekt) und den neuen Start vormerken — er feuert, sobald die Buchung geklärt ist.
    public func confirmTakeover() throws {
        guard let takeover = pendingTakeover else { return }
        queuedStart = (takeover.neuesProjektNummer, takeover.neuesProjektTitel, takeover.neueKostenstelle)
        pendingTakeover = nil
        try requestStop()
    }

    public func cancelTakeover() {
        pendingTakeover = nil
    }

    // MARK: Pause / Resume

    public func pause() throws {
        guard var timer = active, timer.isPaused == false else { return }
        let t = now()
        timer.pausedAccumulatedSeconds += max(0, t.timeIntervalSince(timer.runSince))
        timer.isPaused = true
        try persistActive(timer)
        active = timer
    }

    public func resume() throws {
        guard var timer = active, timer.isPaused else { return }
        timer.runSince = now()
        timer.isPaused = false
        try persistActive(timer)
        active = timer
    }

    // MARK: Kostenstellen-Wechsel (kein Zeitverlust)

    /// Schließt den laufenden Abschnitt als Draft ab und startet sofort einen neuen
    /// Abschnitt mit der neuen Kostenstelle — derselbe Timer-Lauf, keine Sekunde verloren,
    /// keine Buchung (die kommt erst beim Stopp + Doppelbestätigung).
    public func switchKostenstelle(to kostenstelle: String) throws {
        guard let timer = active, timer.kostenstelle != kostenstelle else { return }
        let t = now()
        let draft = makeDraft(from: timer, endedAt: t)
        try db.write { dbc in
            try TimeSegmentDraftRecord(from: draft).insert(dbc)
        }
        pendingDrafts.append(draft)
        let next = ActiveTimer(
            projektNummer: timer.projektNummer, projektTitel: timer.projektTitel, kostenstelle: kostenstelle,
            runSince: t, pausedAccumulatedSeconds: 0, isPaused: false, segmentStartedAt: t)
        try persistActive(next)
        active = next
    }

    // MARK: Stopp → Buchungs-Bestätigung

    /// Beendet den laufenden Abschnitt (als finalen Draft), entfernt den ActiveTimer.
    /// Danach ist `active == nil` und `pendingDrafts` enthält den ganzen Lauf →
    /// die UI zeigt die Buchungs-Bestätigung (Schritt 1). NOCH NICHT gebucht.
    public func requestStop() throws {
        guard let timer = active else { return }
        let draft = makeDraft(from: timer, endedAt: now())
        try db.write { dbc in
            if draft.seconds > 0 { try TimeSegmentDraftRecord(from: draft).insert(dbc) }
            try ActiveTimerRecord.deleteAll(dbc)
        }
        if draft.seconds > 0 { pendingDrafts.append(draft) }
        active = nil
        reminderAnchor = nil
        // Sonderfall: Lauf war 0 s und es gab keine vorherigen Drafts → nichts zu buchen.
        if pendingDrafts.isEmpty { runQueuedStartIfNeeded() }
    }

    /// Schritt 2 der Doppelbestätigung: alle Drafts werden als gebuchte Segmente
    /// committet (append-only) und aus den Drafts entfernt.
    public func confirmBooking() throws {
        guard pendingDrafts.isEmpty == false else { return }
        saveState = .saving
        let booked = pendingDrafts.map { TimeSegment(fromDraft: $0, bookedAt: now()) }
        do {
            try db.write { dbc in
                for seg in booked { try TimeSegmentRecord(from: seg).insert(dbc) }
                try TimeSegmentDraftRecord.deleteAll(dbc)
            }
            bookedSegments.insert(contentsOf: booked, at: 0)
            pendingDrafts.removeAll()
            saveState = .saved(now())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
        runQueuedStartIfNeeded()
    }

    /// Verwirft die offene Buchung (Drafts), ohne zu buchen.
    public func cancelBooking() throws {
        guard pendingDrafts.isEmpty == false else { return }
        try db.write { dbc in try TimeSegmentDraftRecord.deleteAll(dbc) }
        pendingDrafts.removeAll()
        runQueuedStartIfNeeded()
    }

    private func runQueuedStartIfNeeded() {
        guard let q = queuedStart else { return }
        // queuedStart bleibt gesetzt, bis der Start WIRKLICH erfolgreich war — sonst
        // ginge der vorgemerkte Übernahme-Start bei einem DB-Fehler lautlos verloren
        // (der Nutzer dächte, sein Timer läuft, obwohl keiner gestartet wurde). Fehler
        // wird über saveState sichtbar; der Queue-Eintrag überlebt für einen Retry.
        do {
            try startFresh(projektNummer: q.projektNummer, projektTitel: q.projektTitel, kostenstelle: q.kostenstelle)
            queuedStart = nil
        } catch {
            saveState = .failed(error.localizedDescription)
        }
    }

    // MARK: Puls-Erinnerung

    /// Setzt die Erinnerungs-Uhr zurück (Check-in „Läuft weiter").
    public func resetReminder() {
        reminderAnchor = now()
    }

    /// Soll die Sidebar gerade pulsieren? Reine Wall-Clock-Logik seit `reminderAnchor`:
    /// nach jeder Intervall-Marke pulst es `calmAfterSeconds` lang (Default 180 s = 3 Min),
    /// danach Ruhe bis zur nächsten Marke. Pausierter Timer pulst nie.
    public func shouldPulse() -> Bool {
        guard let anchor = reminderAnchor, let timer = active, timer.isPaused == false else { return false }
        return Self.shouldPulse(
            anchor: anchor, now: now(),
            intervalSeconds: Double(pulseIntervalMinutes) * 60, calmAfterSeconds: 180)
    }

    /// Reine, testbare Puls-Entscheidung.
    public static func shouldPulse(anchor: Date, now: Date, intervalSeconds: Double, calmAfterSeconds: Double = 180) -> Bool {
        guard intervalSeconds > 0 else { return false }
        let elapsed = now.timeIntervalSince(anchor)
        guard elapsed >= intervalSeconds else { return false }   // erste Marke noch nicht erreicht
        let calm = min(calmAfterSeconds, intervalSeconds)
        let intoMark = elapsed.truncatingRemainder(dividingBy: intervalSeconds)
        return intoMark < calm
    }

    public func setPulseInterval(minutes: Int) throws {
        let m = max(1, minutes)
        let ts = now().timeIntervalSince1970
        try db.write { dbc in
            try AppSettingRow(key: Self.pulseIntervalKey, value: String(m), updatedAt: ts).save(dbc)
        }
        pulseIntervalMinutes = m
    }

    // MARK: Zielkontingent (S1: Feldgerüst + lokales Editieren)

    public func zielkontingent(for projektNummer: String) -> ProjectZielkontingent? {
        zielkontingente[projektNummer]
    }

    public func setZielkontingent(projektNummer: String, stunden: Double, herkunft: ZielkontingentHerkunft = .manuell) throws {
        let z = ProjectZielkontingent(projektNummer: projektNummer, zielStunden: max(0, stunden), herkunft: herkunft, updatedAt: now())
        try db.write { dbc in try ZielkontingentRecord(from: z).save(dbc) }
        zielkontingente[projektNummer] = z
    }

    /// Gebuchte Stunden je Projekt (Summe der gebuchten Segmente).
    public func gebuchteStunden(for projektNummer: String) -> Double {
        bookedSegments.filter { $0.projektNummer == projektNummer }.reduce(0) { $0 + $1.seconds } / 3600
    }

    // MARK: - Helfer

    private func makeDraft(from timer: ActiveTimer, endedAt: Date) -> TimeSegmentDraft {
        let seconds = timer.elapsedSeconds(now: endedAt)
        return TimeSegmentDraft(
            projektNummer: timer.projektNummer, projektTitel: timer.projektTitel, kostenstelle: timer.kostenstelle,
            startedAt: timer.segmentStartedAt, endedAt: endedAt, seconds: seconds)
    }

    private func persistActive(_ timer: ActiveTimer) throws {
        try db.write { dbc in
            try ActiveTimerRecord.deleteAll(dbc)
            try ActiveTimerRecord(from: timer).insert(dbc)
        }
    }
}
