import Foundation

// MARK: - AntiDuplikat
// mykilOS 8, Block C (S2): Dublettenschutz VOR jeder Kunden-/Projekt-Anlage
// (HANDOFF_PROVISIONING_NOMENKLATUR §4). Nie Kunde/Projekt/Nummer stumm doppeln —
// bei Treffer „verknüpfen statt neu anlegen" anbieten. Reine, testbare Logik: nimmt
// Kandidat + Bestand, liefert Treffer mit Grund. Die UI entscheidet (Dialog).
public struct DuplikatKandidat: Sendable, Equatable {
    public var name: String?
    public var firma: String?
    public var email: String?
    public var telefon: String?
    public var kundennummer: String?

    public init(name: String? = nil, firma: String? = nil, email: String? = nil,
                telefon: String? = nil, kundennummer: String? = nil) {
        self.name = name; self.firma = firma; self.email = email
        self.telefon = telefon; self.kundennummer = kundennummer
    }
}

public struct DuplikatTreffer: Sendable, Equatable, Identifiable {
    public var id: String { customerNumber + ":" + grund.rawValue }
    public enum Grund: String, Sendable { case kundennummer, email, telefon, name, firma }
    public let customerNumber: String
    public let name: String
    public let grund: Grund
    public let detail: String

    public init(customerNumber: String, name: String, grund: Grund, detail: String) {
        self.customerNumber = customerNumber; self.name = name; self.grund = grund; self.detail = detail
    }
}

public enum AntiDuplikat {
    /// Findet mögliche Kunden-Dubletten. Exakte Treffer (Kdnr/Mail/Tel) sind stark,
    /// Name/Firma sind schwächere Hinweise (normalisierter Vergleich). Sortiert: stärkste zuerst.
    public static func pruefeKunde(_ kandidat: DuplikatKandidat, bestand: [Customer], kontakte: [StudioContact] = []) -> [DuplikatTreffer] {
        var treffer: [DuplikatTreffer] = []

        // 1. Kundennummer exakt (stärkster Treffer — die Kdnr ist eindeutig).
        if let kdnr = nonEmpty(kandidat.kundennummer) {
            for c in bestand where c.customerNumber.caseInsensitiveCompare(kdnr) == .orderedSame {
                treffer.append(DuplikatTreffer(customerNumber: c.customerNumber, name: c.name, grund: .kundennummer, detail: "Kundennummer \(kdnr) existiert bereits"))
            }
        }
        // 2. E-Mail / Telefon exakt — über Kontakte (Customer hält keine Kontaktdaten).
        if let mail = nonEmpty(kandidat.email)?.lowercased() {
            for k in kontakte where k.email?.lowercased() == mail {
                treffer.append(DuplikatTreffer(customerNumber: k.projekt ?? k.id, name: k.name, grund: .email, detail: "E-Mail \(mail) ist bereits bei \(k.name) hinterlegt"))
            }
        }
        if let tel = nonEmpty(kandidat.telefon).map(nurZiffern), tel.isEmpty == false {
            for k in kontakte where k.telefon.map(nurZiffern) == tel {
                treffer.append(DuplikatTreffer(customerNumber: k.projekt ?? k.id, name: k.name, grund: .telefon, detail: "Telefon ist bereits bei \(k.name) hinterlegt"))
            }
        }
        // 3. Name / Firma (schwächer — normalisierter Gleichheitsvergleich).
        if let name = nonEmpty(kandidat.name).map(normalisiere) {
            for c in bestand where normalisiere(c.name) == name {
                treffer.append(DuplikatTreffer(customerNumber: c.customerNumber, name: c.name, grund: .name, detail: "Name „\(c.name)“ existiert bereits"))
            }
        }
        if let firma = nonEmpty(kandidat.firma).map(normalisiere) {
            for c in bestand where normalisiere(c.name) == firma {
                treffer.append(DuplikatTreffer(customerNumber: c.customerNumber, name: c.name, grund: .firma, detail: "Firma „\(c.name)“ existiert bereits"))
            }
        }

        // Dedupe (gleicher Kunde mehrfach) + stärkste Gründe zuerst.
        let rang: [DuplikatTreffer.Grund: Int] = [.kundennummer: 0, .email: 1, .telefon: 2, .name: 3, .firma: 4]
        var gesehen = Set<String>()
        return treffer
            .sorted { (rang[$0.grund] ?? 9) < (rang[$1.grund] ?? 9) }
            .filter { gesehen.insert($0.customerNumber + ":" + $0.grund.rawValue).inserted }
    }

    // MARK: Helfer
    static func nonEmpty(_ s: String?) -> String? {
        guard let v = s?.trimmingCharacters(in: .whitespacesAndNewlines), v.isEmpty == false else { return nil }
        return v
    }
    static func nurZiffern(_ s: String) -> String { String(s.filter(\.isNumber)) }
    static func normalisiere(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
