import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - ProvisioningMode
// mykilOS 8, Block A: der TEST/PROD-Schalter aus HANDOFF_TEST_SANDBOX.md §6.
// Default `.test`. `.prod` ist für Block A bewusst GESPERRT (siehe `ProvisioningModeStore.
// setMode`) — die Freigabe kommt erst, wenn (a) die Nomenklatur bestätigt ist (Block C),
// (b) die Lern-Runde aus dem Bestand gelaufen ist, (c) Johannes es explizit freigibt.
public enum ProvisioningMode: String, Codable, Sendable, CaseIterable {
    case test
    case prod
}

// MARK: - AppSettingRecord (GRDB, generisch)
private struct AppSettingRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "appSettings" }
    var key: String
    var value: String
    var updatedAt: Double
}

// MARK: - ProvisioningModeStore
// Persistiert den Schalter in der generischen `appSettings`-Tabelle. Schreiben wirft;
// `.prod` ist hart gesperrt, bis Block D/G die Freigabe-Bedingungen erfüllt — siehe
// `prodUnlockReason`. Das ist KEIN Settings-UI-Feature in Block A, nur die Mechanik.
@MainActor
@Observable
public final class ProvisioningModeStore {
    public private(set) var mode: ProvisioningMode = .test
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase
    private static let settingKey = "provisioningMode"

    public init(db: GRDBDatabase) {
        self.db = db
    }

    public func load() throws {
        let record = try db.read { dbConn in
            try AppSettingRecord.fetchOne(dbConn, key: Self.settingKey)
        }
        if let record, let loaded = ProvisioningMode(rawValue: record.value) {
            mode = loaded
        } else {
            mode = .test
        }
    }

    /// Wirft `ProvisioningModeError.prodLocked`, solange Block A/C/D `.prod` nicht
    /// freigegeben haben. Es gibt bewusst KEINEN Override-Parameter — die Sperre lebt
    /// im Code, nicht in einem Flag, das versehentlich umgelegt werden könnte.
    public func setMode(_ newMode: ProvisioningMode) throws {
        guard newMode == .test else {
            throw ProvisioningModeError.prodLocked
        }
        saveState = .saving
        do {
            try db.write { dbConn in
                try AppSettingRecord(key: Self.settingKey, value: newMode.rawValue,
                                      updatedAt: Date().timeIntervalSince1970).save(dbConn)
            }
            mode = newMode
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}

public enum ProvisioningModeError: Error, Sendable, Equatable, LocalizedError {
    case prodLocked
    public var errorDescription: String? {
        "PROD-Modus ist gesperrt, bis Nomenklatur (Block C) + Lern-Runde + Johannes' ausdrückliche Freigabe vorliegen."
    }
}

// MARK: - TestMarker
// Die Doppel-Strategie aus HANDOFF_TEST_SANDBOX.md §3: Name/Primärfeld-Präfix
// `TEST_…` UND ein Feld `Quelle = "TEST"`. Beide müssen stimmen — eine Heuristik
// allein ist zu schwach, um Produktivdaten sicher auszuschließen.
public enum TestMarker {
    public static let namePrefix = "TEST_"
    public static let quelleFieldValue = "TEST"

    public static func isTestRecord(name: String?, quelle: String?) -> Bool {
        (name?.hasPrefix(namePrefix) == true) && (quelle == quelleFieldValue)
    }
}
