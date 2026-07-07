import Foundation
import MykilosKit

// MARK: - TimelineItem / TimelineSource (L27)
// Ein Ereignis auf der Projekt-Zeitachse. Quelle als plain enum — MykilosServices
// importiert KEIN SwiftUI/Design, daher mappt erst die View (TimelineRow) die Quelle
// auf eine MykColor. So bleibt die Merge-Logik pur und testbar.
public struct TimelineItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let date: Date
    public let title: String
    public let subtitle: String?
    public let source: TimelineSource
    public let webViewLink: String?
    /// Für Drive-/Angebots-Ereignisse: die zugrundeliegende Datei — trägt die
    /// In-App-Vorschau (Sammlungs-Ansicht-Standard). `nil` bei Kalender/Audit.
    public let driveFile: GoogleDriveFile?

    public init(id: String, date: Date, title: String, subtitle: String?,
                source: TimelineSource, webViewLink: String?,
                driveFile: GoogleDriveFile? = nil) {
        self.id = id; self.date = date; self.title = title
        self.subtitle = subtitle; self.source = source; self.webViewLink = webViewLink
        self.driveFile = driveFile
    }
}

public enum TimelineSource: Sendable, Equatable { case drive, offer, calendar, audit }

public extension AuditEntry.Action {
    /// Deutsches Anzeige-Label für die Zeitachse (pure, testbar).
    var timelineLabel: String {
        switch self {
        case .offerImported:      "Angebot importiert"
        case .draftCreated:       "Entwurf erstellt"
        case .draftSent:          "Entwurf gesendet"
        case .projectLinked:      "Projekt verknüpft"
        case .noteUpdated:        "Notiz geändert"
        case .estimateAdjusted:   "Schätzung angepasst"
        case .calibrationPromoted:"Kalibrierung übernommen"
        case .contactCreated:     "Kontakt angelegt"
        case .driveFileUploaded:  "Datei hochgeladen"
        case .warenkorbGesendet:  "Warenkorb gesendet"
        case .mailAktionAusgefuehrt: "Mail-Aktion"
        case .inviteCreated:      "Einladung erstellt"
        case .clickUpStatusChanged: "ClickUp-Status geändert"
        case .clickUpTaskCreated: "ClickUp-Aufgabe angelegt"
        case .clickUpGoLiveFreigegeben: "ClickUp-Liste Go-Live freigeschaltet"
        case .clickUpGoLiveGesperrt: "ClickUp-Liste Go-Live gesperrt"
        }
    }
}

// MARK: - TimelineMerger
// Führt die vier Quellen (Drive-Dateien, Angebote, Kalender, Audit) zu EINER
// absteigend sortierten Ereignisliste zusammen. Reine Funktion → unit-testbar.
public enum TimelineMerger {

    public static func merge(
        driveFiles: [GoogleDriveFile],
        offers: OffersCollector.Result,
        calendarEvents: [GoogleCalendarEvent],
        auditEntries: [AuditEntry]
    ) -> [TimelineItem] {
        var items: [TimelineItem] = []

        // Angebote zuerst (reicheres Signal) — ihre Datei-IDs entdoppeln die Drive-Liste.
        var offerFileIDs = Set<String>()
        for offer in offers.incoming + offers.outgoing {
            guard let date = offer.file.modifiedAt else { continue }
            offerFileIDs.insert(offer.file.id)
            var subtitle = offer.type.label
            if let nr = offer.belegNummer { subtitle += " · \(nr)" }
            items.append(TimelineItem(
                id: "offer:\(offer.file.id)", date: date, title: offer.file.name,
                subtitle: subtitle, source: .offer, webViewLink: offer.file.webViewLink,
                driveFile: offer.file))
        }

        // Drive-Dateien: Ordner, datumslose und bereits als Angebot gezeigte überspringen.
        for file in driveFiles {
            guard file.isFolder == false, let date = file.modifiedAt,
                  offerFileIDs.contains(file.id) == false else { continue }
            items.append(TimelineItem(
                id: "drive:\(file.id)", date: date, title: file.name,
                subtitle: file.typeLabel, source: .drive, webViewLink: file.webViewLink,
                driveFile: file))
        }

        // Kalender (kommende Termine).
        for event in calendarEvents {
            guard let date = event.startsAt else { continue }
            items.append(TimelineItem(
                id: "cal:\(event.id)", date: date, title: event.title,
                subtitle: event.location, source: .calendar, webViewLink: nil))
        }

        // Audit (bestätigte Aktionen).
        for entry in auditEntries {
            items.append(TimelineItem(
                id: "audit:\(entry.id.uuidString)", date: entry.timestamp,
                title: entry.action.timelineLabel, subtitle: entry.summary,
                source: .audit, webViewLink: nil))
        }

        return items.sorted { $0.date > $1.date }
    }
}
