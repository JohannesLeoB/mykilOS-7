import Foundation
import Observation

/// Sicherheitsstufe einer Aktion, die der Satellit RAUSSENDET.
/// Steuert, ob "immer erlauben" angeboten werden darf (Johannes, 04.07.).
enum SicherheitsStufe {
    /// Irreversibel / Geld / Vertrag / fremde Systeme / privat.
    case hoch
    /// Reversibel, kleiner Radius.
    case mittel
    /// Rein lokal, kein Aussen-Effekt.
    case niedrig

    var brauchtBestaetigung: Bool { self != .niedrig }
    /// Nur mittlere Aktionen duerfen dauerhaft freigegeben werden.
    var darfImmerErlauben: Bool { self == .mittel }
}

/// Merkt die "immer erlauben"-Entscheidungen pro Aktionstyp (nur fuer
/// mittlere Sicherheit). Widerrufbar in den Einstellungen.
@Observable
final class FreigabeStore {
    private let key = "freigaben_immer_erlaubt"
    private(set) var erlaubt: Set<String>

    init() { erlaubt = Set(UserDefaults.standard.stringArray(forKey: key) ?? []) }

    func istImmerErlaubt(_ aktion: String) -> Bool { erlaubt.contains(aktion) }
    func merke(_ aktion: String) { erlaubt.insert(aktion); speichern() }
    func widerrufe(_ aktion: String) { erlaubt.remove(aktion); speichern() }
    func allesZuruecksetzen() { erlaubt = []; speichern() }

    private func speichern() {
        UserDefaults.standard.set(Array(erlaubt), forKey: key)
    }
}

/// Wie wird dieses Geraet genutzt?
enum GeraeteModus: String, Codable, CaseIterable, Identifiable {
    /// Ein Nutzer, eigenes Geraet - bleibt gebrieft.
    case persoenlich
    /// Werkstatt-/Leihgeraet, viele Nutzer - Login/Logout je Sitzung.
    case geteilt

    var id: String { rawValue }
    var titel: String { self == .persoenlich ? "Persoenlich" : "Geteilt (Werkstatt)" }
}

/// Bindung des Satelliten an genau EINE Mothership/Nutzer. "Ich beame nicht
/// in Fraukes Account" (Johannes). Auf persoenlichen Geraeten warnt ein
/// Besitzer-Wechsel; auf geteilten Geraeten ist Wechsel = Login, und
/// Abmelden wischt die privaten Zugaenge.
/// Ergebnis der Pruefung, ob ein Kopplungs-Paket uebernommen werden darf.
enum KopplungsPruefung {
    /// Erste Kopplung oder gleicher Nutzer - einfach uebernehmen.
    case inOrdnung
    /// Anderer Nutzer, aber gleiche Firma - auf geteiltem Geraet = Login,
    /// auf persoenlichem Geraet Warnung ("wirklich wechseln?").
    case nutzerWechsel(vorher: String, jetzt: String)
    /// ANDERE Firma - der Kosmos wechselt. Das soll praktisch nie passieren
    /// (ein Geraet gehoert zu einer Firma). Harte Warnung.
    case fremderKosmos(vorher: String, jetzt: String)
}

/// Bindung des Satelliten an EINEN Kosmos (Firma/Mothership) und den aktuell
/// angemeldeten Nutzer + Rolle. Zwei Ebenen (Johannes):
/// - Kosmos = eine Firma, eine Mothership, kennt alle User + Rollen. Das
///   Geraet gehoert zu genau einem Kosmos.
/// - Sitzung = welcher Nutzer (mit welcher Rolle) gerade angemeldet ist.
///   Persoenliches Geraet: fix. Geteiltes Geraet: wechselt per Login/Logout.
@Observable
final class MothershipBindung {
    private let firmaKey = "mothership_firma"
    private let besitzerKey = "mothership_besitzer"
    private let rolleKey = "mothership_rolle"
    private let modusKey = "geraete_modus"

    private(set) var firma: String?
    private(set) var besitzer: String?
    private(set) var rolle: String?
    var modus: GeraeteModus {
        didSet { UserDefaults.standard.set(modus.rawValue, forKey: modusKey) }
    }

    init() {
        firma = UserDefaults.standard.string(forKey: firmaKey)
        besitzer = UserDefaults.standard.string(forKey: besitzerKey)
        rolle = UserDefaults.standard.string(forKey: rolleKey)
        modus = GeraeteModus(rawValue: UserDefaults.standard.string(forKey: modusKey) ?? "") ?? .persoenlich
    }

    /// Darf dieses Paket uebernommen werden?
    func pruefe(firma neueFirma: String?, benutzer neuerBenutzer: String) -> KopplungsPruefung {
        if let firma, !firma.isEmpty, let neueFirma, !neueFirma.isEmpty,
           firma.lowercased() != neueFirma.lowercased() {
            return .fremderKosmos(vorher: firma, jetzt: neueFirma)
        }
        if let besitzer, !besitzer.isEmpty, besitzer.lowercased() != neuerBenutzer.lowercased() {
            return .nutzerWechsel(vorher: besitzer, jetzt: neuerBenutzer)
        }
        return .inOrdnung
    }

    func binde(firma neueFirma: String?, besitzer neuerBesitzer: String, rolle neueRolle: String?) {
        firma = neueFirma
        besitzer = neuerBesitzer
        rolle = neueRolle
        UserDefaults.standard.set(neueFirma, forKey: firmaKey)
        UserDefaults.standard.set(neuerBesitzer, forKey: besitzerKey)
        UserDefaults.standard.set(neueRolle, forKey: rolleKey)
    }

    /// Abmelden = De-Brief: alle gekoppelten Zugaenge aus dem Schluesselbund
    /// wischen, Nutzer-Sitzung loesen, Freigaben zuruecksetzen. Sicherer
    /// Default fuer ein geteiltes Geraet, bevor der naechste Nutzer koppelt.
    /// Die Firma-Bindung (Kosmos) bleibt - das Geraet gehoert weiter zur Firma.
    func abmelden(freigaben: FreigabeStore) {
        try? KeychainAirtablePostboxCredentialsStore().clear()
        try? KeychainClaudeCredentialsStore().clear()
        try? KeychainFireflyCredentialsStore().clear()
        // Clockodo: sobald ein mobiler Clockodo-Store existiert, hier mit wischen.
        besitzer = nil
        rolle = nil
        UserDefaults.standard.removeObject(forKey: besitzerKey)
        UserDefaults.standard.removeObject(forKey: rolleKey)
        freigaben.allesZuruecksetzen()
    }
}
