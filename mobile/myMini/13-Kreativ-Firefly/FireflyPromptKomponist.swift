import Foundation

/// Der Schlussstein (#47): baut aus einem `KreativBrief` einen fertigen,
/// fotorealistischen Render-Prompt. Bewusst auf ENGLISCH — Bildgeneratoren
/// (Firefly, aber auch jeder andere) liefern mit englischen Prompts spuerbar
/// bessere, konsistentere Ergebnisse; der Prompt ist Maschinen-Anweisung,
/// kein Text zum Lesen. Eine deutsche Kurzfassung liegt daneben, damit
/// Johannes sieht, was drinsteht.
///
/// Ehrliche Grenze: Der Prompt komponiert sich hier aus den EINGETIPPTEN
/// Zutaten. Sobald die Mothership-Antenne steht, koennen Geraeteliste
/// (Warenkorb) und exakte Farben (ColorReader) automatisch einfliessen —
/// der Komponist bleibt derselbe, er bekommt dann nur reichere Zutaten.
enum FireflyPromptKomponist {
    /// Kuratierte Stil-Liste fuer Kuechen/Innenraum — Auswahl statt Freitext,
    /// damit der Prompt konsistent bleibt.
    static let stile = [
        "Modern", "Grifflos", "Landhaus", "Skandinavisch",
        "Industrial", "Minimalistisch", "Klassisch", "Mediterran"
    ]

    private static let stilEnglisch: [String: String] = [
        "Modern": "modern", "Grifflos": "handleless modern",
        "Landhaus": "country-style", "Skandinavisch": "Scandinavian",
        "Industrial": "industrial", "Minimalistisch": "minimalist",
        "Klassisch": "classic", "Mediterran": "Mediterranean"
    ]

    /// Der englische Render-Prompt zum Kopieren/Einfuegen in Firefly.
    static func komponiere(_ brief: KreativBrief) -> String {
        let stil = stilEnglisch[brief.stil] ?? brief.stil.lowercased()
        var zeilen: [String] = []
        let stilTeil = stil.isEmpty ? "kitchen" : "\(stil) kitchen"
        zeilen.append("Photorealistic interior photograph of a \(stilTeil) integrated into this existing room, keeping the room's walls, windows and proportions.")
        if let referenz = brief.referenzName, !referenz.trimmingCharacters(in: .whitespaces).isEmpty {
            zeilen.append("Match the style, quality and craftsmanship of the attached reference kitchen.")
        }
        let material = brief.materialFarbe.trimmingCharacters(in: .whitespacesAndNewlines)
        if !material.isEmpty {
            zeilen.append("Cabinetry and materials: \(material).")
        }
        let elemente = brief.elemente.trimmingCharacters(in: .whitespacesAndNewlines)
        if !elemente.isEmpty {
            zeilen.append("Key elements: \(elemente).")
        }
        let zusatz = brief.zusatz.trimmingCharacters(in: .whitespacesAndNewlines)
        if !zusatz.isEmpty {
            zeilen.append(zusatz)
        }
        zeilen.append("Natural daylight, wide-angle architectural interior photography, realistic materials, accurate reflections, true-to-scale proportions, high detail.")
        return zeilen.joined(separator: " ")
    }

    /// Variante fuer Photoshops "Generatives Fuellen": beschreibt gezielt,
    /// was in den markierten Bereich des echten Raumfotos soll — kein ganzes
    /// Bild, sondern das eingesetzte Objekt. Kuerzer, ohne "photograph of a
    /// room"-Rahmen, dafuer mit Anschluss an Licht/Perspektive des Fotos.
    static func komponiereGenerativeFill(_ brief: KreativBrief) -> String {
        let stil = stilEnglisch[brief.stil] ?? brief.stil.lowercased()
        var teile: [String] = []
        teile.append(stil.isEmpty ? "a fitted kitchen" : "a \(stil) fitted kitchen")
        let material = brief.materialFarbe.trimmingCharacters(in: .whitespacesAndNewlines)
        if !material.isEmpty { teile.append(material) }
        let elemente = brief.elemente.trimmingCharacters(in: .whitespacesAndNewlines)
        if !elemente.isEmpty { teile.append(elemente) }
        var satz = teile.joined(separator: ", ")
        satz += ", photorealistic, matching the room's existing lighting, perspective and scale"
        let zusatz = brief.zusatz.trimmingCharacters(in: .whitespacesAndNewlines)
        if !zusatz.isEmpty { satz += ". \(zusatz)" }
        return satz
    }

    /// Kurze deutsche Erklaerung, was der Prompt beschreibt.
    static func deutscheZusammenfassung(_ brief: KreativBrief) -> String {
        var teile: [String] = []
        if !brief.stil.isEmpty { teile.append("Stil: \(brief.stil)") }
        if !brief.materialFarbe.isEmpty { teile.append("Material/Farbe: \(brief.materialFarbe)") }
        if !brief.elemente.isEmpty { teile.append("Elemente: \(brief.elemente)") }
        return teile.isEmpty ? "Noch keine Zutaten gewaehlt." : teile.joined(separator: " - ")
    }
}
