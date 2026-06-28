import Foundation
import MykilosKit

// MARK: - AssistantGrounding
// Baut den System-Prompt für den Chat. Erdet die Antworten an echten App-Kontext
// (Datum, fokussiertes Projekt, offene Signale, Projektliste), damit der Assistent
// nicht halluziniert. Phase 1: KEINE Live-Tools — der Prompt sagt das explizit,
// damit der Assistent keine erfundenen „Suchergebnisse" behauptet.
public enum AssistantGrounding {

    public static func systemPrompt(
        profile: UserProfile? = nil,
        focusedProjectID: String?,
        signals: [WidgetSignal],
        projects: [Project],
        now: Date,
        toolsEnabled: Bool = false,
        kalkulationsEnabled: Bool = false,
        driveEnabled: Bool = false,
        contactsEnabled: Bool = false,
        clickUpEnabled: Bool = false,
        studioBrainEnabled: Bool = false,
        katalogEnabled: Bool = false
    ) -> String {
        var lines: [String] = []
        var intro = "Du bist der mykilOS-Projektassistent für ein Design-/Küchenstudio. "
        if let profile, profile.isComplete {
            intro += "Du sprichst mit \(profile.displayName)"
            if profile.role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                intro += " (\(profile.role))"
            }
            intro += ". "
        }
        intro += "Antworte auf Deutsch — direkt, knapp und sachlich wie ein erfahrener Kollege. "
        intro += "Keine Emojis. Keine Ausrufezeichen als Einleitung. "
        intro += "Keine Floskeln (nie: 'Gerne!', 'Natürlich!', 'Ich bin bereit', 'Lass uns loslegen', 'Super!'). "
        intro += "Kein KI-Selbstbezug (nie: 'Als KI', 'Als Assistent', 'Ich kann dir helfen mit'). "
        intro += "Wenn Informationen fehlen: kurz benennen was fehlt — nicht entschuldigen."
        lines.append(intro)
        lines.append("Heute ist \(dateString(now)).")

        if let focusedProjectID, let project = projects.first(where: { $0.projectNumber == focusedProjectID }) {
            var p = "Aktuell im Fokus: \(project.title) (\(project.projectNumber))"
            if let phase = project.phase { p += ", Phase \(phase)" }
            p += "."
            lines.append(p)
        }

        lines.append("")
        lines.append("Offene Signale:")
        lines.append(signals.isEmpty ? "- keine" : signals.map(describe(signal:)).joined(separator: "\n"))

        if projects.isEmpty == false {
            lines.append("")
            lines.append("Projekte im Studio:")
            lines.append(projects.prefix(40).map { "- \($0.projectNumber): \($0.title)" }.joined(separator: "\n"))
        }

        lines.append("")
        if toolsEnabled {
            var toolLines: [String] = [
                "Wichtig: Erfinde keine Fakten. Du hast LIVE-Lesezugriff auf folgende Werkzeuge — nutze sie statt zu raten:",
                "- search_gmail: Gmail durchsuchen (Betreff/Snippet).",
                "- list_calendar_events: Termine aus Google Kalender.",
                "- suggest_calendar_event: erzeugt einen Kalender-Link (kein API-Write).",
            ]
            if driveEnabled {
                toolLines.append("- list_drive_folder: Dateien und Unterordner im verlinkten Drive-Projektordner (nur Metadaten lesen). Mit 'unterordner' gezielt z. B. in '01 ANGEBOTE' schauen.")
            }
            if contactsEnabled {
                toolLines.append("- search_contacts: Kontakte des verbundenen Accounts per Freitext suchen.")
            }
            if clickUpEnabled {
                toolLines.append("- list_clickup_tasks: offene ClickUp-Aufgaben dieses Projekts (Status, Fälligkeit).")
            }
            if studioBrainEnabled {
                toolLines.append("- query_studio_knowledge: Studio-Wissensbasis aus der Projekthistorie (Projekte, Lieferanten, Team, Problem-Signale, Preis-Nennungen). Nutze sie für Fragen zu früheren/laufenden Projekten und Lieferanten.")
            }
            if katalogEnabled {
                toolLines.append("- search_katalog: Artikel- und Gerätekatalog durchsuchen (Gaggenau, Miele, Blum, Häfele…). Gibt Hersteller, Beschreibung, Artikelnummer und MYKILOS-VK. Nützlich für Preisfragen zu konkreten Geräten.")
            }
            if kalkulationsEnabled {
                toolLines.append("- schaetze_projekt: Kostenschätzung (Min/Mitte/Max-Netto) aus der lokalen Kalkulationsdatenbank.")
            }
            var toolMsg = toolLines.joined(separator: "\n")
            toolMsg += "\nWenn für eine Frage kein Werkzeug oben passt (z. B. Rechnungen), sag offen, dass dir der Live-Zugriff fehlt. "
            toolMsg += "Mails versenden darfst du nur als Vorschlag formulieren, nie als erledigt darstellen."
            lines.append(toolMsg)
        } else {
            lines.append(
                "Wichtig: Erfinde keine Fakten. Du hast in dieser Version KEINE Live-Zugriffe auf "
                + "Mails, Kalender, Drive oder Aufgaben — beziehe dich nur auf den oben gegebenen Kontext "
                + "und sage offen, wenn dir Informationen fehlen. Schreibaktionen (Mails, Termine) darfst "
                + "du nur als Vorschlag formulieren, nie als bereits erledigt darstellen."
            )
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Helfer (deterministisch)

    private static func dateString(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: date)
    }

    private static func describe(signal: WidgetSignal) -> String {
        switch signal {
        case .projectFocused(let p):                 "- Projekt fokussiert: \(p)"
        case .driveFileAdded(let p, let name):       "- Drive-Datei in \(p): \(name)"
        case .offerDetected(let p, let label):       "- Angebot in \(p): \(label)"
        case .reviewSuggested(let p, let label):     "- Review-Vorschlag in \(p): \(label)"
        case .budgetThresholdCrossed(let p, let r):  "- Budget in \(p): \(Int(r * 100)) Prozent"
        case .deadlineNear(let p, let days):         "- Deadline in \(p): \(days) Tage"
        }
    }
}
