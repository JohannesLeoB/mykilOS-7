import Foundation

// MARK: - DriveFolderSuggestion

/// Ein vorgeschlagenes Upload-Ziel, das dem Assistenten oder der UI präsentiert wird.
/// Der User muss explizit bestätigen — kein Auto-Upload.
public struct DriveFolderSuggestion: Equatable, Sendable {
    /// Drive-Ordner-ID (direkt als `parentFolderID` für `GoogleDriveClient.uploadFile` nutzbar).
    public let folderID: String
    /// Menschenlesbarer Name des Ordners (für Action-Card).
    public let folderName: String
    /// Optionaler Hinweis, warum dieser Ordner vorgeschlagen wird.
    public let reason: String

    public init(folderID: String, folderName: String, reason: String) {
        self.folderID = folderID
        self.folderName = folderName
        self.reason = reason
    }
}

// MARK: - DriveFolderSuggestionError

public enum DriveFolderSuggestionError: Error, Sendable, Equatable {
    /// Kein Drive-Ordner für dieses Projekt konfiguriert.
    case noDriveFolderConfigured
    /// Upload-Ziel ist der NO-GO-Root-Ordner — niemals hochladen.
    case uploadDestinationForbidden(String)
}

// MARK: - DriveFolderSuggestionResolver

/// Ermittelt zu einem Projekt den passenden Drive-Upload-Ordner.
///
/// Quellen (in dieser Priorität):
/// 1. `projectDriveFolderID` — direkte Ordner-ID aus Airtable `Projekte.Drive-Ordner-ID`
/// 2. Unterordner via `driveClient.listFolder` (z. B. „05 eingehende Angebote")
///
/// Rein testbar: Netzwerk-Zugriff ausschließlich über injizierten `GoogleDriveFetching`.
/// HARTE Grenze: `forbiddenFolderIDs` werden immer abgelehnt.
public struct DriveFolderSuggestionResolver: Sendable {

    private let driveClient: GoogleDriveFetching

    /// NO-GO-Ordner-IDs, die NIEMALS Upload-Ziel sein dürfen.
    /// `0AOeReQBQKkKBUk9PVA` = geteilter Drive-Root (CLAUDE.md, read-only).
    public static let forbiddenFolderIDs: Set<String> = [
        "0AOeReQBQKkKBUk9PVA",
    ]

    public init(driveClient: GoogleDriveFetching) {
        self.driveClient = driveClient
    }

    // MARK: - Haupt-API

    /// Gibt einen Vorschlag zurück (oder wirft), ohne irgendetwas zu schreiben.
    /// Der Aufrufer (Action-Card → Bestätigung → `GoogleDriveClient.uploadFile`) entscheidet.
    ///
    /// - Parameters:
    ///   - projectDriveFolderID: Drive-Ordner-ID aus `ProjectLinks.driveFolderID`.
    ///   - preferredSubfolderKeyword: Optionales Schlüsselwort zur Unterordner-Auswahl
    ///     (z. B. „Angebote"). Wird case-insensitiv gegen Unterordnernamen geprüft.
    public func suggest(
        projectDriveFolderID: String?,
        preferredSubfolderKeyword: String? = nil
    ) async throws -> DriveFolderSuggestion {
        guard let rootID = projectDriveFolderID, !rootID.isEmpty else {
            throw DriveFolderSuggestionError.noDriveFolderConfigured
        }

        // NO-GO-Guard — wirft sofort, bevor irgendein Netzwerkaufruf stattfindet.
        try Self.assertNotForbidden(rootID)

        // Unterordner suchen wenn Keyword gegeben
        if let keyword = preferredSubfolderKeyword, !keyword.isEmpty {
            if let sub = try await findSubfolder(in: rootID, keyword: keyword) {
                return sub
            }
        }

        // Fallback: Projekt-Wurzelordner selbst
        let name: String
        do {
            name = try await driveClient.getFileName(folderID: rootID)
        } catch {
            // getFileName ist ein Nice-to-have — bei Fehler Platzhalter nutzen
            name = rootID
        }
        return DriveFolderSuggestion(
            folderID: rootID,
            folderName: name,
            reason: "Projekt-Ordner"
        )
    }

    // MARK: - Testbare Helfer (intern, aber im selben Modul)

    /// Wirft `.uploadDestinationForbidden` wenn `folderID` auf der NO-GO-Liste steht.
    static func assertNotForbidden(_ folderID: String) throws {
        if forbiddenFolderIDs.contains(folderID) {
            throw DriveFolderSuggestionError.uploadDestinationForbidden(folderID)
        }
    }

    /// Sucht im Ordner `parentID` nach einem Unterordner dessen Name `keyword` enthält
    /// (case-insensitiv). Gibt nil zurück wenn keiner gefunden — kein Fehler.
    private func findSubfolder(in parentID: String, keyword: String) async throws -> DriveFolderSuggestion? {
        let entries = try await driveClient.listFolder(folderID: parentID)
        guard let match = entries.first(where: {
            $0.isFolder && $0.name.localizedCaseInsensitiveContains(keyword)
        }) else {
            return nil
        }
        // Unterordner selbst auch gegen NO-GO prüfen (defensive)
        guard !Self.forbiddenFolderIDs.contains(match.id) else {
            return nil
        }
        return DriveFolderSuggestion(
            folderID: match.id,
            folderName: match.name,
            reason: "Unterordner fuer \"\(keyword)\""
        )
    }
}
