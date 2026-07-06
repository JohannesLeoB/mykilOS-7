import Foundation

// MARK: - NachfassAlertPreferences (Backlog "Nachtrag 2026-07-02 spät", 2026-07-07)
// Rein lokale UserDefaults-Präferenz (gleiches Muster wie TaskAlarmPreferences) — kein
// GRDB nötig, kein Server. Global aktiv per Default (dezent, kein Popup), Schwelle
// konfigurierbar (Default 14 Tage laut Backlog-Vorschlag "N Tage ohne Reaktion").
public enum NachfassAlertPreferences {
    private static let enabledKey = "nachfass.global"
    private static let schwelleKey = "nachfass.schwelle.tage"

    public static var aktiv: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    public static var schwelleInTagen: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: schwelleKey) as? Int
            return stored ?? 14
        }
        set { UserDefaults.standard.set(newValue, forKey: schwelleKey) }
    }
}

// MARK: - NachfassAlertComputer (2026-07-07)
// Ehrliche Einschränkung (siehe docs/IDEEN_UND_BACKLOG.md, Nachtrag 2026-07-02 spät):
// es gibt KEIN echtes "Kunde hat reagiert"-Signal — `GoogleDriveFile.modifiedAt` ist nur
// der Drive-Änderungszeitpunkt der Angebots-Datei selbst, kein Beweis für Kundenreaktion.
// Diese reine Alters-Heuristik ("seit X Tagen unverändert") ist bewusst NUR für AUSGEHENDE
// Belege gedacht und wird der UI immer als Alters-Hinweis beschriftet, nie als "keine
// Reaktion bestätigt" — Ehrlichkeits-Vorgabe aus demselben Backlog-Abschnitt.
public enum NachfassAlertComputer {
    /// `true`, wenn ein ausgehender Beleg seit mindestens `schwelleInTagen` Tagen
    /// unverändert ist (Alters-Proxy, keine echte Reaktionsprüfung). Eingehende Belege
    /// werden nie geflaggt — Nachfassen betrifft nur das eigene ausgehende Angebot.
    public static func istFaellig(
        _ offer: AllOffersCollector.AggregatedOffer, schwelleInTagen: Int, now: Date = Date()
    ) -> Bool {
        guard offer.direction == .outgoing, schwelleInTagen > 0 else { return false }
        guard let modifiedAt = offer.offer.file.modifiedAt else { return false }
        let tageSeitAenderung = Calendar.current.dateComponents([.day], from: modifiedAt, to: now).day ?? 0
        return tageSeitAenderung >= schwelleInTagen
    }

    /// Anzahl Tage seit der letzten Änderung — für die UI-Beschriftung ("seit 21 Tagen").
    public static func tageSeitAenderung(_ offer: AllOffersCollector.AggregatedOffer, now: Date = Date()) -> Int? {
        guard let modifiedAt = offer.offer.file.modifiedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: modifiedAt, to: now).day
    }
}

// MARK: - BitteReagierenAlertPreferences (Backlog "Nachtrag 2026-07-02 spät", 2026-07-07)
// Gegenrichtung zu NachfassAlertPreferences: eingehendes Ding ohne EIGENE Reaktion,
// statt ausgehendes Angebot ohne Kundenreaktion. Gleiche Alters-Schwellen-Logik,
// eigener Toggle + eigene Schwelle (unabhängig einstellbar).
public enum BitteReagierenAlertPreferences {
    private static let enabledKey = "bittereagieren.global"
    private static let schwelleKey = "bittereagieren.schwelle.tage"

    public static var aktiv: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    public static var schwelleInTagen: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: schwelleKey) as? Int
            return stored ?? 14
        }
        set { UserDefaults.standard.set(newValue, forKey: schwelleKey) }
    }
}

// MARK: - BitteReagierenAlertComputer (2026-07-07)
// Ehrliche Einschränkung wie bei NachfassAlertComputer: `modifiedAt` beweist nur, seit
// wann das eingehende Dokument im Drive unverändert liegt — kein Beweis, dass Johannes
// tatsächlich noch nicht reagiert hat (eine Antwort könnte z.B. rein per Telefon erfolgt
// sein). Reiner Alters-Hinweis, NUR für EINGEHENDE Belege — Gegenrichtung zu
// NachfassAlertComputer (dort: ausgehend).
public enum BitteReagierenAlertComputer {
    /// `true`, wenn ein eingehender Beleg seit mindestens `schwelleInTagen` Tagen
    /// unverändert liegt (Alters-Proxy). Ausgehende Belege werden nie geflaggt.
    public static func istFaellig(
        _ offer: AllOffersCollector.AggregatedOffer, schwelleInTagen: Int, now: Date = Date()
    ) -> Bool {
        guard offer.direction == .incoming, schwelleInTagen > 0 else { return false }
        guard let modifiedAt = offer.offer.file.modifiedAt else { return false }
        let tageSeitEingang = Calendar.current.dateComponents([.day], from: modifiedAt, to: now).day ?? 0
        return tageSeitEingang >= schwelleInTagen
    }
}
