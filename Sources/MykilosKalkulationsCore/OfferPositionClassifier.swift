import Foundation

// MARK: - OfferPositionClassifier (PDF-Positions v1 · Bauteil-Kategorie)
//
// Ordnet einem herausgelösten Positionsblock eine `ComponentType`-Kategorie zu —
// aus dem Text (Titel + Block), per Küchen-Domänen-Schlüsselwörtern. Reicher als
// `ComponentType.fromBrainComponent` (das nur ein Kategorie-Label mappt), weil hier
// der ganze Positionstext betrachtet wird. Foundation-only, rein → testbar.
//
// Wozu: (1) Kategorie-Chip pro Karte im Sheet (schnelleres Scannen für den Menschen);
// (2) Voraussetzung für den späteren Lern-Loop — ein Preis-Anker ohne Bauteil-Typ ist
// wertlos, denn Preise sind nur INNERHALB einer Kategorie vergleichbar.
//
// Reihenfolge = spezifisch vor generisch (erste Regel gewinnt). Bewusst konservativ:
// im Zweifel `.other` statt falsch einzusortieren.
public enum OfferPositionClassifier {

    public static func classify(text: String) -> ComponentType {
        let t = text.lowercased()
        func has(_ needles: [String]) -> Bool { needles.contains { t.contains($0) } }

        // 1. Arbeitsplatte / Stein (sehr charakteristisches Vokabular)
        if has(["arbeitsplatte", "naturstein", "quarzit", "quarz", "granit", "keramik",
                "dekton", "silestone", "marmor", "hartgestein", "wange", " apl", "wandabschluss"]) {
            return .stoneCountertop
        }
        // 2. Schubkästen / Beschläge / Auszüge
        if has(["schubkasten", "schublade", "auszug", "besteckeinsatz", "beschlag",
                "kesseböhmer", "kessebohmer", "tandem", "griffleiste", "scharnier"]) {
            return .drawerAddon
        }
        // 3. Hochschrank / Apothekerschrank
        if has(["hochschrank", "apothekerschrank", "vorratsschrank"]) { return .tallCabinetBlock }
        // 4. Hängeschrank / Oberschrank
        if has(["hängeschrank", "haengeschrank", "oberschrank"]) { return .wallCabinets }
        // 5. Insel / Kochinsel
        if has(["kochinsel", "insel"]) { return .island }
        // 6. Geräte (Marken + Gattungen)
        if has(["kochfeld", "backofen", "geschirrspüler", "geschirrspueler", "kühlschrank",
                "kuehlschrank", "gefrier", "dunstabzug", "abzugshaube", "mikrowelle", "spüle",
                "spuele", "armatur", "quooker", "bora", "gaggenau", "miele", "siemens",
                "neff ", "liebherr", "allesschneider"]) {
            return .applianceScope
        }
        // 7. Unterschränke / Küchenzeile / Korpus / Fronten
        if has(["unterschrank", "küchenzeile", "kuechenzeile", "küchenblock", "kuechenblock",
                "korpus", "front", "einbauschrank", "regalböden", "regalboeden"]) {
            return .baseCabinetRun
        }
        // 8. Montage / Einbau
        if has(["montage", "einbau", "aufbau", "einbringung"]) { return .installation }
        // 9. Lieferung / Logistik / Aufmaß / Pauschalen
        if has(["lieferung", "anlieferung", "anfahrt", "transport", "fahrkosten", "aufmaß",
                "aufmass", "handling", "logistik", "an- und abfahrt", "pauschale", "pflegemittel"]) {
            return .projectLogistics
        }
        // 10. Gesamtküche
        if has(["gesamtküche", "gesamtkueche", "komplettküche", "komplettkueche"]) {
            return .aggregateKitchen
        }
        return .other
    }
}
