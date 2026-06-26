import Foundation
import Observation
import MykilosKit

// MARK: - DriveOfferWatcher
// Die echte Live-Quelle für `offerDetected` — der lange als „geplant" markierte
// Drive-Webhook. Ein echter Google-Push-Webhook bräuchte eine öffentliche
// Callback-URL und damit ein Backend; mykilOS ist local-first. Daher pollt der
// Watcher den verlinkten Drive-Ordner (read-only, `files.list` über den
// bestehenden `GoogleDriveClient`) und meldet **neue** Angebots-/Rechnungs-PDFs.
//
// Wichtige Semantik: Der erste Poll legt nur eine Baseline an (markiert alle
// aktuell vorhandenen Treffer als „gesehen") und meldet NICHTS — sonst würde
// beim Öffnen eines Projekts jedes alte Angebot fälschlich als „neu" fluten.
// Erst danach erzeugt ein wirklich neu aufgetauchtes PDF ein Signal.
//
// Signale bleiben VORSCHLÄGE: `offerDetected` → Mediator leitet
// `reviewSuggested` ab, das CashWidget zeigt einen Hinweis. Es wird nie etwas
// geschrieben — das liefe über Action-Card → Bestätigung → Audit.
@MainActor
@Observable
public final class DriveOfferWatcher {
    private let client: GoogleDriveFetching
    private var seen: Set<String> = []
    private var baselined = false

    public init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    /// Ein Poll-Durchlauf. Liefert die neu erkannten Angebots-Signale (leer beim
    /// Baseline-Lauf, bei Auth-/Netzwerkfehlern und wenn nichts Neues da ist).
    /// Fehler werden bewusst geschluckt: ein Hintergrund-Poll darf die UI nie
    /// mit Fehlerzuständen stören — das übernimmt das DriveWidget selbst.
    public func poll(projectID: String, folderID: String) async -> [WidgetSignal] {
        guard folderID.isEmpty == false else { return [] }
        guard let files = try? await client.listFolder(folderID: folderID) else { return [] }

        let offers = Self.detectOffers(in: files)

        guard baselined else {
            seen = Set(offers.map(\.id))
            baselined = true
            return []
        }

        let fresh = offers.filter { seen.contains($0.id) == false }
        seen.formUnion(fresh.map(\.id))
        return fresh.map { .offerDetected(projectID: projectID, label: $0.name) }
    }

    // MARK: - Reine, testbare Kernlogik (kein Netzwerk/Zustand)

    // Ein „Angebot" ist ein PDF, dessen Name auf einen Angebots-/Rechnungs-
    // Beleg hindeutet. Bewusst konservativ und gut dokumentiert: lieber ein
    // Beleg verpassen als jeden Drive-Upload als Angebot melden.
    // `public`, damit die Angebote-Tab dieselbe Erkennung nutzt wie das Signal —
    // eine Quelle der Wahrheit (keine zweite, abweichende Heuristik in der UI).
    public static let offerKeywords = ["angebot", "rechnung", "kostenvoranschlag", "offer", "invoice"]

    public static func detectOffers(in files: [GoogleDriveFile]) -> [GoogleDriveFile] {
        files.filter { isOffer($0) }
    }

    public static func isOffer(_ file: GoogleDriveFile) -> Bool {
        guard file.mimeType == "application/pdf" else { return false }
        let name = file.name.lowercased()
        return offerKeywords.contains { name.contains($0) }
    }
}
