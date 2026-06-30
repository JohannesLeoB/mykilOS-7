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
        allClickUpEnabled: Bool = false,
        draftEnabled: Bool = false,
        contactsWriteEnabled: Bool = false,
        kontaktVerzeichnisEnabled: Bool = false,
        studioBrainEnabled: Bool = false,
        katalogEnabled: Bool = false,
        notesEnabled: Bool = false,
        tasksEnabled: Bool = false,
        offersEnabled: Bool = false,
        fileReadEnabled: Bool = false
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
        lines.append("Gedächtnis: Der bisherige Gesprächsverlauf der letzten ~4 Wochen steht dir als "
            + "Nachrichtenhistorie zur Verfügung — er ist lokal gespeichert und überlebt App-Neustarts. "
            + "Knüpfe selbstverständlich an frühere Gespräche an (etwa 'von vorhin', 'gestern', 'letzte Woche'). "
            + "Behaupte NIEMALS, du hättest kein Gedächtnis oder würdest nach jedem Chat alles vergessen — "
            + "das ist falsch. Steht etwas Älteres als 4 Wochen oder gar nicht im Verlauf, sag das schlicht.")

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
                "- search_gmail: Gmail durchsuchen (Betreff/Snippet). Mit 'anzahl' mehr Treffer für Rückblicke; Gmail-Operatoren wie 'after:2025/01/01' nutzbar. Die Suche umfasst das GANZE Postfach.",
                "- read_email: den VOLLEN Inhalt einer gefundenen Mail lesen (nicht nur die Vorschau).",
                "- list_calendar_events: Termine aus Google Kalender.",
                "- suggest_calendar_event: erzeugt einen Kalender-Link (kein API-Write).",
            ]
            if draftEnabled {
                toolLines.append("- create_draft: bereitet einen E-Mail-ENTWURF vor (Betreff/Text/optional Empfänger). Es entsteht eine Bestätigungskarte; der Nutzer legt den Entwurf in Gmail ab. Du VERSENDEST NIE und behauptest nie, die Mail sei gesendet/gespeichert.")
            }
            if driveEnabled {
                toolLines.append("- list_drive_folder: Dateien und Unterordner im verlinkten Drive-Projektordner (nur Metadaten lesen). Mit 'unterordner' gezielt z. B. in '01 INFOS' schauen.")
            }
            if offersEnabled {
                toolLines.append("- find_offers: Angebote & Rechnungen im Drive finden (eingehend/ausgehend, auch verschachtelt in '01 INFOS'). Im Projekt-Chat automatisch; sonst Projekt per 'projekt' nennen. Nutze DIESES Werkzeug für Angebots-/Rechnungsfragen statt zu sagen, Drive sei außer Reichweite.")
            }
            if fileReadEnabled {
                toolLines.append("- read_drive_file: liest den INHALT einer Drive-Datei (PDF, Google Docs/Sheets/Slides, Text) als Klartext. Nutze es, um z. B. einen Fragebogen oder ein Angebot auszuwerten — du hast also sehr wohl Lesezugriff auf Dateiinhalte, behaupte nicht das Gegenteil. 'datei' = (Teil des) Dateinamens.")
            }
            if contactsEnabled {
                toolLines.append("- search_contacts: Kontakte des verbundenen Accounts per Freitext suchen.")
            }
            if contactsWriteEnabled {
                toolLines.append("- create_contact: schlägt einen NEUEN Google-Kontakt vor. Du schreibst NICHT selbst — es entsteht eine Bestätigungskarte, der Nutzer legt den Kontakt an. Nenne die Kontaktdaten, behaupte aber nie, der Kontakt sei schon gespeichert.")
            }
            if kontaktVerzeichnisEnabled {
                toolLines.append("- lookup_kontakt: Airtable-Kontaktverzeichnis (Kunden, Lieferanten, Handwerker, Team) mit Telefon, E-Mail und ADRESSE. Nutze DIESES Werkzeug für Adress-/Telefon-/E-Mail-Fragen zu Personen (z. B. „Adresse Cirnavuk?“) — es ist lokal verfügbar, du musst dafür nicht auf Google warten.")
                toolLines.append("- list_airtable_kontakte / search_airtable_kontakt: dieselbe Airtable-Kontaktbasis auflisten bzw. durchsuchen (Name, Organisation, Kategorie, Telefon, E-Mail). Du HAST also Zugriff auf die Kontakte — behaupte nie das Gegenteil.")
                toolLines.append("- create_airtable_kontakt / update_airtable_kontakt: schlägt vor, einen Airtable-Kontakt ANZULEGEN oder zu ÄNDERN. Du schreibst NICHT selbst — es entsteht eine Bestätigungskarte, der Nutzer bestätigt (+ Audit). KEIN Löschen.")
            }
            if clickUpEnabled {
                toolLines.append("- list_clickup_tasks: offene ClickUp-Aufgaben dieses Projekts (Status, Fälligkeit).")
            }
            if allClickUpEnabled {
                toolLines.append("- list_all_clickup_tasks: PROJEKTÜBERGREIFENDE Übersicht aller offenen ClickUp-Aufgaben, gruppiert nach Projekt. Nutze es für „Was steht insgesamt/überall offen?“.")
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
            if notesEnabled {
                toolLines.append("- create_note / list_notes / update_note / delete_note: persistente Notizen & Erinnerungen lokal verwalten. Wenn der Nutzer etwas notieren oder sich erinnern lassen will, lege es mit create_note an (überlebt den Neustart) — KEIN Kalender-Link nötig.")
            }
            if tasksEnabled {
                toolLines.append("- create_task / list_tasks / complete_task / delete_task: interne Aufgabenliste (To-dos/Erinnerungen) lokal verwalten. Für kleine Memos und Erinnerungen, die der Nutzer sich selbst setzt; optionales Fälligkeitsdatum (yyyy-MM-dd). Abhaken mit complete_task, entfernen mit delete_task.")
            }
            var toolMsg = toolLines.joined(separator: "\n")
            toolMsg += "\nWenn für eine Frage kein Werkzeug oben passt (z. B. Rechnungen), sag offen, dass dir der Live-Zugriff fehlt. "
            toolMsg += "Mails kannst du als ENTWURF vorbereiten (create_draft, mit Bestätigung) — VERSENDEN tust du nie und stellst es nie als erledigt dar."
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
