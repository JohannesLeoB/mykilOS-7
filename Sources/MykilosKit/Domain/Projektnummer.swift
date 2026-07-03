import Foundation

// MARK: - Projektnummer
// mykilOS 8, Block C (S2): die eine, einmalige Projektnummer `JJJJ_NNN` (Jahr + 3-stellige
// laufende Nr). Aus dem echten Bestand gelernt (HANDOFF_PROVISIONING_NOMENKLATUR §1):
// strikt max+1, keine Lücken auffüllen, nie wiederverwenden. Ist Teil des Drive-Ordner-/
// Projektnamens. NICHT die Kundennummer (die ist getrennt, nicht fortlaufend).
//
// Tolerantes Parsen (Bestand zeigt Anomalien wie `2026_20` ohne führende Null) →
// normalisiert immer auf 3-stellig. App-Anzeige `JJJJ-NNN`, Drive-Ordner `JJJJ_NNN`.
public struct Projektnummer: Codable, Hashable, Sendable, Comparable, CustomStringConvertible {
    public let jahr: Int
    public let laufendeNummer: Int

    public init(jahr: Int, laufendeNummer: Int) {
        self.jahr = jahr
        self.laufendeNummer = laufendeNummer
    }

    /// Parst tolerant `JJJJ_NNN`, `JJJJ-NNN`, auch ohne führende Nullen (`2026_20`).
    /// Nimmt die ERSTEN beiden Zahlengruppen; ignoriert angehängte Slug-/Adressteile
    /// (`2026_015_Schmidt_HEI8` → 2026/015). Gibt nil, wenn kein Jahr+Nr erkennbar.
    public init?(parsing raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Erste Zahlengruppe = Jahr (4-stellig), zweite = laufende Nr.
        let groups = trimmed
            .split(whereSeparator: { !$0.isNumber })
            .map(String.init)
        guard groups.count >= 2,
              let jahr = Int(groups[0]), jahr >= 2000, jahr < 3000,
              let nr = Int(groups[1]), nr >= 0 else { return nil }
        self.jahr = jahr
        self.laufendeNummer = nr
    }

    /// App-Anzeige: `2026-030`.
    public var appFormat: String { String(format: "%04d-%03d", jahr, laufendeNummer) }
    /// Drive-Ordner-Präfix: `2026_030`.
    public var driveFormat: String { String(format: "%04d_%03d", jahr, laufendeNummer) }
    public var description: String { appFormat }

    public static func < (lhs: Projektnummer, rhs: Projektnummer) -> Bool {
        lhs.jahr != rhs.jahr ? lhs.jahr < rhs.jahr : lhs.laufendeNummer < rhs.laufendeNummer
    }

    // MARK: Vergabe-Logik (rein, testbar)

    /// Nächste freie Nummer im Jahr = max(laufende Nr dieses Jahres) + 1, mindestens 1.
    /// Berücksichtigt ALLE übergebenen Nummern (aktiv + archiviert). Strikt max+1 —
    /// füllt KEINE Lücken (Bestand-Regel: 005/008-011 bleiben frei, nächste ist 030).
    public static func next(jahr: Int, vorhandene: [Projektnummer]) -> Projektnummer {
        let maxImJahr = vorhandene.filter { $0.jahr == jahr }.map(\.laufendeNummer).max() ?? 0
        return Projektnummer(jahr: jahr, laufendeNummer: maxImJahr + 1)
    }
}
