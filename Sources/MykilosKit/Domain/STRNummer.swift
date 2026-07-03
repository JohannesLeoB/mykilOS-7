import Foundation

// MARK: - STRNummer
// mykilOS 8, Block C (S2): der letzte Block des Projektordnernamens `JJJJ_NNN_Kunde_STR-Nr`
// (HANDOFF_PROVISIONING_NOMENKLATUR §2). Default-Regel: abgekürzte Straße der Baustelle +
// Hausnummer (Großbuchstaben), z. B. HEI8 = Heimhuder 8, KOE66, MUE71. Fallback: ORT
// (Stadt der Baustelle). Plus eine bestätigte Varianten-Whitelist für Nicht-Baustellen-
// Projekte (Geraete/Herd/Quooker/Lightnet/…). Kann der Block weder als Adresse noch per ORT
// noch als Variante gebildet werden → Warnung + Block (kein schema-brechender Ordner).
//
// Abkürzungsregel (aus dem Bestand abgeleitet, konsistent über alle Beispiele):
// Umlaute transliterieren (ö→oe, ü→ue, ä→ae, ß→ss), Nicht-Buchstaben entfernen,
// erste 3 Buchstaben, Großbuchstaben — „Königstraße"→KOE, „Heimhuder"→HEI, „Müllerweg"→MUE.
public enum STRNummerQuelle: String, Codable, Sendable, Equatable {
    case adresse   // Straße + Hausnummer
    case ort       // Fallback: Stadt
    case variante  // bestätigte Nicht-Adress-Variante (Whitelist)
}

public enum STRNummerErgebnis: Sendable, Equatable {
    case gebildet(String, quelle: STRNummerQuelle)
    case nichtBildbar(grund: String)   // → Maske muss warnen + Anlage blocken
}

public enum STRNummer {
    /// Default-Whitelist der Nicht-Adress-Varianten aus dem echten Bestand
    /// (HANDOFF_PROVISIONING_NOMENKLATUR §2). Erweiterbar — Johannes bestätigt/ergänzt.
    public static let defaultVariantenWhitelist: Set<String> = [
        "GERAETE", "HERD", "QUOOKER", "LIGHTNET", "SERIENKUECHE", "W-BANK", "KV5",
    ]

    /// Bildet den STR-Block nach der Default-Regel mit Whitelist-Prüfung.
    /// Reihenfolge: explizite Variante (Whitelist) → Adresse → ORT-Fallback → nicht bildbar.
    public static func bilde(
        strasse: String?, hausnummer: String?, ort: String?,
        variante: String? = nil,
        whitelist: Set<String> = defaultVariantenWhitelist
    ) -> STRNummerErgebnis {
        // 1. Explizite Variante (z. B. „Geräte-Projekt") — nur wenn auf der Whitelist.
        if let variante, variante.trimmingCharacters(in: .whitespaces).isEmpty == false {
            let norm = normalisiereVariante(variante)
            if whitelist.contains(norm) {
                return .gebildet(norm, quelle: .variante)
            }
            return .nichtBildbar(grund: "Variante „\(variante)“ ist nicht auf der bestätigten Whitelist. Adresse/ORT angeben oder Variante freigeben.")
        }
        // 2. Adresse: Straße (abgekürzt) + Hausnummer.
        if let kuerzel = strassenKuerzel(strasse) {
            let hn = ziffern(hausnummer)
            return .gebildet(kuerzel + hn, quelle: .adresse)
        }
        // 3. ORT-Fallback (Stadt der Baustelle, gleiche Abkürzung).
        if let ortKuerzel = strassenKuerzel(ort) {
            return .gebildet(ortKuerzel, quelle: .ort)
        }
        // 4. Nichts bildbar → Warnung + Block.
        return .nichtBildbar(grund: "Kein Adressblock bildbar: weder Straße noch ORT vorhanden, keine bestätigte Variante.")
    }

    // MARK: - Bausteine (rein, testbar)

    /// Erste 3 Buchstaben (transliteriert, Großbuchstaben). nil wenn < 1 Buchstabe.
    public static func strassenKuerzel(_ s: String?) -> String? {
        guard let s else { return nil }
        let buchstaben = transliteriere(s).filter { $0.isLetter }
        guard buchstaben.isEmpty == false else { return nil }
        return String(buchstaben.prefix(3)).uppercased()
    }

    /// Nur Ziffern aus der Hausnummer (8, 66, 71); leer wenn keine.
    public static func ziffern(_ s: String?) -> String {
        guard let s else { return "" }
        return String(s.filter(\.isNumber))
    }

    /// Trennt ein kombiniertes "Straße + Nr."-Feld (z. B. aus dem Fragebogen, wo Straße
    /// und Hausnummer EIN Textfeld sind) in Straße + Hausnummer, damit `bilde(...)`
    /// wie gewohnt beide getrennt bekommt. Erkennt einen Hausnummer-Block am Ende
    /// (Ziffern + optionalem Leerzeichen + optionalem Buchstaben-Suffix, optional gefolgt
    /// von „-" oder „/" + einem zweiten Block: "8", "12a", "10 b", "3-5", "4/2").
    /// Review-Fix: die ursprüngliche Regel erkannte "10 b" (Leerzeichen vor Suffix) und
    /// "4/2" (Schrägstrich-Zusatz) NICHT und ließ dann `bilde(...)` still eine unvollständige
    /// STR-Nr ohne Hausnummer bilden, statt zu warnen — jetzt korrekt erkannt.
    /// Kein erkennbarer Block → alles bleibt Straße, Hausnummer nil.
    public static func splitStrasseHausnummer(_ kombiniert: String?) -> (strasse: String?, hausnummer: String?) {
        guard let kombiniert else { return (nil, nil) }
        let getrimmt = kombiniert.trimmingCharacters(in: .whitespacesAndNewlines)
        guard getrimmt.isEmpty == false else { return (nil, nil) }
        guard let treffer = getrimmt.range(
            of: #"\s+\d+\s?[a-zA-Z]?([/-]\d+\s?[a-zA-Z]?)?$"#, options: .regularExpression
        ) else {
            return (getrimmt, nil)
        }
        let hausnummer = getrimmt[treffer].trimmingCharacters(in: .whitespaces)
        let strasse = String(getrimmt[getrimmt.startIndex..<treffer.lowerBound])
            .trimmingCharacters(in: .whitespaces)
        return (strasse.isEmpty ? nil : strasse, hausnummer)
    }

    static func normalisiereVariante(_ v: String) -> String {
        transliteriere(v).uppercased().trimmingCharacters(in: .whitespaces)
    }

    /// Deutsche Umlaute/ß → ASCII (ö→oe, ü→ue, ä→ae, ß→ss).
    static func transliteriere(_ s: String) -> String {
        var out = ""
        for ch in s {
            switch ch {
            case "ä", "Ä": out += "ae"
            case "ö", "Ö": out += "oe"
            case "ü", "Ü": out += "ue"
            case "ß":      out += "ss"
            default:       out.append(ch)
            }
        }
        return out
    }
}
