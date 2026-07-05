import Foundation
import MykilosKit

// MARK: - AuditStoreCheckInSink
//
// Dünner Wrapper: erfüllt das Foundation-only-Protokoll `CheckInAuditSink`
// (MykilosKit) über den bestehenden, bereits cold-start-getesteten `AuditStore`
// (MykilosServices/GRDB). KEIN neuer Store, KEINE neue Persistenz — die eine
// Audit-Spur bleibt der bestehende `AuditStore`.
//
// Nahtpunkt-Detail: `AuditStore.append` ist `@MainActor` + `throws` + NICHT async;
// `CheckInAuditSink.schreibe` ist `async throws`. Der Wrapper hüpft explizit auf den
// MainActor: `await MainActor.run { try store.append(entry) }`. Der Fehler propagiert
// unverändert (nicht verschluckt), der SaveState des Stores bleibt sichtbar.
public struct AuditStoreCheckInSink: CheckInAuditSink {
    private let store: AuditStore

    public init(store: AuditStore) {
        self.store = store
    }

    public func schreibe(_ entry: AuditEntry) async throws {
        try await MainActor.run {
            try store.append(entry)
        }
    }
}
