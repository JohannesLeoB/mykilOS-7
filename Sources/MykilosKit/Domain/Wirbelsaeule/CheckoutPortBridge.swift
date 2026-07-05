import Foundation

// MARK: - CheckoutPortBridge
//
// Brücke: macht aus JEDEM bestehenden `CheckoutPort` einen `CheckInAdapter`, ohne
// die Ports zu ändern. So docken Sevdesk-Postbox, Dokument-, Moodboard-, Firefly-Port
// an die Spine an, ohne dass ihr Code angefasst wird.
//
// HARTE MODULREGEL: Foundation-only (MykilosKit). Keine Persistenz, keine UI.
//
// Der Adapter delegiert:
//   vorschau  → port.preview   (schreibt nichts)
//   fuehreAus → port.execute   (der einzige schreibende Aufruf)
// Die Duplikat-Erkennung bleibt im Default `false` — die Port-eigene Idempotenz
// (z. B. SevdeskPostboxCheckoutPort.objektHash) lebt weiter IM Port; die Spine
// erzwingt zusätzlich die zentrale Audit-Idempotenz über den deterministischen Key.

public struct CheckoutPortAsCheckInAdapter: CheckInAdapter {
    /// Der gewrappte, unveränderte CheckoutPort.
    private let port: any CheckoutPort
    /// Grober Audit-Kanal für die Ausführung dieses Ports (Default: generischer Checkout).
    private let kanal: AuditKanal

    public init(port: any CheckoutPort, kanal: AuditKanal = .checkoutAusgefuehrt) {
        self.port = port
        self.kanal = kanal
    }

    public var id: PortID { port.id }
    public var name: String { port.name }

    public func erlaubteInhaltsArten() -> Set<InhaltsArt> {
        port.erlaubteInhaltsArten()
    }

    /// Deterministischer Schlüssel: stabiler Hash aus Korb-ID + Ziel-Kind +
    /// sortierten Ziel-Parametern. KEIN Date()/UUID() — reproduzierbar über Läufe
    /// und Prozess-Neustarts hinweg (FNV-1a, plattform-stabil, anders als Hasher).
    public func idempotenzSchluessel(
        _ gegenstand: CheckInGegenstand,
        _ absicht: CheckInAbsicht
    ) -> String {
        let sortierteParameter = absicht.ziel.parameter
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        let roh = "\(port.id.raw)|\(gegenstand.id.raw)|v\(gegenstand.version)|\(absicht.ziel.kind)|\(sortierteParameter)"
        return CheckInHash.stabil(roh)
    }

    public func vorschau(
        _ gegenstand: CheckInGegenstand,
        _ absicht: CheckInAbsicht
    ) async throws -> CheckInVorschau {
        let preview = try await port.preview(basket: gegenstand, ziel: absicht.ziel)
        return CheckInVorschau(
            vorschau: preview,
            idempotenzSchluessel: idempotenzSchluessel(gegenstand, absicht),
            istDuplikat: false   // Port-eigene Idempotenz bleibt im Port; Default hier: nicht-Duplikat.
        )
    }

    public func fuehreAus(
        _ gegenstand: CheckInGegenstand,
        _ absicht: CheckInAbsicht
    ) async throws -> CheckInAusfuehrung {
        let ergebnis = try await port.execute(basket: gegenstand, ziel: absicht.ziel)
        return CheckInAusfuehrung(ergebnis: ergebnis, kanal: kanal, summaryDetail: ergebnis.referenz)
    }
}

// MARK: - CheckInHash

/// Kleiner, plattform-stabiler String-Hash (FNV-1a, 64-bit) für deterministische
/// Idempotenz-Schlüssel. Bewusst NICHT Swift-`Hasher` (der ist pro-Prozess geseedet
/// und damit über Neustarts hinweg NICHT reproduzierbar). Foundation-only.
public enum CheckInHash {
    public static func stabil(_ input: String) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325   // FNV offset basis
        let prime: UInt64 = 0x0000_0100_0000_01b3   // FNV prime
        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return String(hash, radix: 16)
    }
}
