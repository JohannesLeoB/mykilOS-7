import Foundation

// MARK: - OfferReviewCheckInAdapter
//
// Der erste native CheckIn-Adapter (kein CheckoutPort-Wrapper): „ein erkanntes
// Drive-Eingangsangebot in Review übernehmen". Es gibt hier KEINEN externen Write —
// der Vorgang IST der Audit-Eintrag (genau wie die alte CashWidget.confirmReview nur
// einen AuditEntry(.offerImported) schrieb). Der Adapter liefert daher nur ein
// Erfolgs-Ergebnis + den Kanal `.angebotImportiert`; die Spine schreibt das Audit.
//
// HARTE MODULREGEL: Foundation-only (MykilosKit).
//
// Idempotenz: der Schlüssel ist deterministisch aus Projektnummer + Angebots-Label
// (kein Date()/UUID()). Zweimal dasselbe Angebot für dasselbe Projekt → gleicher Key
// → der PARTIAL UNIQUE INDEX auf auditEntries.idempotenzKey wehrt den zweiten Write ab.
public struct OfferReviewCheckInAdapter: CheckInAdapter {
    public static let portID = PortID("offer-review")

    public var id: PortID { Self.portID }
    public var name: String { "Angebot in Review" }

    public init() {}

    public func erlaubteInhaltsArten() -> Set<InhaltsArt> {
        // Ein Eingangsangebot ist ein Dokument/gemischter Vorgang; wir erlauben beides.
        [.dokumente, .gemischt]
    }

    public func idempotenzSchluessel(
        _ gegenstand: CheckInGegenstand,
        _ absicht: CheckInAbsicht
    ) -> String {
        let label = absicht.ziel.parameter["angebotLabel"] ?? ""
        let projekt = absicht.projektNummer ?? gegenstand.projektNummer
        return "offer-review|" + CheckInHash.stabil("\(projekt)|\(label)")
    }

    public func vorschau(
        _ gegenstand: CheckInGegenstand,
        _ absicht: CheckInAbsicht
    ) async throws -> CheckInVorschau {
        let label = absicht.ziel.parameter["angebotLabel"] ?? "Eingangsangebot"
        return CheckInVorschau(
            vorschau: CheckoutPreview(zusammenfassung: "Angebot \(label) in Review übernehmen"),
            idempotenzSchluessel: idempotenzSchluessel(gegenstand, absicht),
            istDuplikat: false   // harte Idempotenz liegt im DB-Constraint, nicht hier.
        )
    }

    public func fuehreAus(
        _ gegenstand: CheckInGegenstand,
        _ absicht: CheckInAbsicht
    ) async throws -> CheckInAusfuehrung {
        // Kein externer Write — der Audit-Eintrag ist der ganze Effekt.
        CheckInAusfuehrung(
            ergebnis: CheckoutResult(erfolg: true, referenz: nil, meldung: "in Review übernommen"),
            kanal: .angebotImportiert,
            summaryDetail: nil
        )
    }
}
