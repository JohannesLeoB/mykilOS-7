import Foundation

// MARK: - ClickUpProjectTemplate
// mykilOS 8, Studio-OS-Rollout (2026-07-02): der kanonische Lebenszyklus für ein neu
// geborenes Kundenprojekt in ClickUp. Bewusst identisch mit den 8 Tasks, die im echten
// Testspace-Seed-Projekt "KUE-2026-014 Küche Müller TEST" bereits von Hand angelegt
// wurden (01 Kundenprojekte) — EINE Wahrheit für die Lebenszyklus-Reihenfolge, nicht
// zwei leicht abweichende Listen in Code und ClickUp.
public enum ClickUpProjectTemplate {
    /// Reihenfolge ist Bedeutung — die Tasks werden in dieser Reihenfolge angelegt.
    public static let standardKundenprojekt: [String] = [
        "Lead / Anfrage qualifizieren",
        "Briefing prüfen",
        "Aufmaß / Termin vorbereiten",
        "Planung starten",
        "Angebot vorbereiten",
        "Bestellung prüfen",
        "Montagefenster abstimmen",
        "Abschluss / Review",
    ]
}
