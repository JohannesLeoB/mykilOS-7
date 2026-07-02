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

    /// Ein Poll-Durchlauf. Liefert alle neuen Signale: `offerDetected` für neue
    /// Angebots-PDFs, `driveFileAdded` für alle anderen neuen Dateien.
    /// Leer beim Baseline-Lauf, bei Auth-/Netzwerkfehlern und wenn nichts Neues da ist.
    /// Fehler werden bewusst geschluckt: ein Hintergrund-Poll darf die UI nie
    /// mit Fehlerzuständen stören — das übernimmt das DriveWidget selbst.
    public func poll(projectID: String, folderID: String) async -> [WidgetSignal] {
        guard folderID.isEmpty == false else { return [] }
        guard let files = try? await client.listFolder(folderID: folderID) else { return [] }

        let nonFolders = files.filter { $0.mimeType != "application/vnd.google-apps.folder" }

        guard baselined else {
            seen = Set(nonFolders.map(\.id))
            baselined = true
            return []
        }

        let fresh = nonFolders.filter { seen.contains($0.id) == false }
        seen.formUnion(fresh.map(\.id))
        return fresh.map { file in
            Self.isOffer(file)
                ? .offerDetected(projectID: projectID, label: file.name)
                : .driveFileAdded(projectID: projectID, fileName: file.name)
        }
    }

    // MARK: - Reine, testbare Kernlogik (kein Netzwerk/Zustand)

    // Ein „Angebot" ist ein PDF, dessen Name auf einen Angebots-/Rechnungs-
    // Beleg hindeutet. Bewusst konservativ und gut dokumentiert: lieber ein
    // Beleg verpassen als jeden Drive-Upload als Angebot melden.
    // `public`, damit die Angebote-Tab dieselbe Erkennung nutzt wie das Signal —
    // eine Quelle der Wahrheit (keine zweite, abweichende Heuristik in der UI).
    nonisolated public static let offerKeywords = ["angebot", "rechnung", "kostenvoranschlag", "offer", "invoice"]

    // MARK: - Akzeptierte Beleg-Dateitypen (EINE Quelle der Wahrheit)
    // Angebote/Belege sind NIE ZIP oder .numbers: **meist PDF** (primär),
    // **manchmal Bilder** (sekundär, z.B. abfotografierte Angebote), **selten Mail**.
    // Alles andere (ZIP, .numbers, Office-Tabellen, Sonstiges) fällt raus. Diese
    // Whitelist gilt für den Angebote-Tab, „Alle Angebote" UND das offerDetected-
    // Signal — die UI filtert NIEMALS ein zweites Mal (kein abweichender Filter).
    nonisolated public static let acceptedOfferExtensions: Set<String> = [
        "pdf",                                                              // primär
        "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "gif", "webp", // Bilder
        "eml", "msg"                                                        // Mail (selten)
    ]
    nonisolated public static let acceptedOfferMimeTypes: Set<String> = [
        "application/pdf",
        "message/rfc822"
    ]

    /// True, wenn die Datei ein plausibler Angebots-/Beleg-Dateityp ist — kein
    /// Ordner, kein ZIP/.numbers/Office-Sonstiges. Endung zuerst (Drive-MIME ist oft
    /// generisch wie `application/octet-stream`); ohne Endung entscheidet die MIME
    /// (PDF/Mail) bzw. das `image/`-Präfix.
    nonisolated public static func isAcceptedOfferFileType(_ file: GoogleDriveFile) -> Bool {
        if file.isFolder { return false }
        let ext = (file.name as NSString).pathExtension.lowercased()
        if ext.isEmpty {
            return acceptedOfferMimeTypes.contains(file.mimeType)
                || file.mimeType.hasPrefix("image/")
        }
        return acceptedOfferExtensions.contains(ext)
    }

    nonisolated public static func detectOffers(in files: [GoogleDriveFile]) -> [GoogleDriveFile] {
        files.filter { isOffer($0) }
    }

    // Ein „Angebot" = akzeptierter Beleg-Dateityp (Whitelist) MIT Angebots-/
    // Rechnungs-Schlüsselwort im Namen. Der Typ-Filter ist die gemeinsame Basis
    // mit dem Angebote-Tab; das Schlüsselwort hält das Signal bewusst konservativ.
    nonisolated public static func isOffer(_ file: GoogleDriveFile) -> Bool {
        guard isAcceptedOfferFileType(file) else { return false }
        let name = file.name.lowercased()
        return offerKeywords.contains { name.contains($0) }
    }
}
