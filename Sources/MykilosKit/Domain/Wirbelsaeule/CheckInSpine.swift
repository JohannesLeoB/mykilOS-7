import Foundation

// MARK: - CheckIn-Spine (Wirbelsäule, die eine Naht)
//
// Der Leitsatz (MASTER_ARCHITEKTUR_CHECKIN.md):
//   „ich hab was → was/wohin/warum → verifizierter Review (okay/nicht okay) → Audit."
//   Append-only, idempotent, nie überschreiben/löschen, Nutzerstempel (WER),
//   throws + SaveState, Cold-Start-safe.
//
// HARTE MODULREGEL: Diese Datei lebt in MykilosKit und importiert AUSSCHLIESSLICH
// Foundation — nie SwiftUI, nie GRDB, nie ein anderes unserer Module. Sie legt NUR
// die Wertetypen + Protokolle + den Orchestrator an. Die schreibende Implementierung
// (AuditStore-Wrapper) liegt in MykilosServices, die Registry-Verdrahtung in MykilosApp.
//
// Diese Naht baut KEINEN neuen Knochen: sie klammert die bestehenden vier
// (WorkBasket/CheckoutPort/PortRightsProviding aus WirbelsaeuleFoundation.swift,
// AuditEntry aus AuditEntry.swift) zu einem zentral auditierten, idempotenten
// Zwei-Schritt-Ablauf zusammen. Bestehende Typen werden UNVERÄNDERT wiederbenutzt.
//
// Concurrency-Hinweis (ehrlich, kein Vorteil, nur Gleichstand): `CheckInGegenstand`
// = `WorkBasket` ist heute NICHT `Sendable` (hält `[any Pick]`, WirbelsaeuleFoundation.swift).
// Unter der aktuellen swift-tools-version 5.10 (kein Swift-6-Language-Mode/StrictConcurrency)
// kompiliert das genau wie die bestehende `CheckoutPort`-Toleranz. Bei einem späteren
// Upgrade auf Swift-6-Mode erzeugen diese `Sendable`-Protokolle dieselbe „non-Sendable
// WorkBasket across async"-Altlast wie CheckoutPort schon heute — sie erben sie, sie
// verbessern sie nicht.

// MARK: - CheckInGegenstand

/// „ich hab was" — der EINE Transport-Typ. Ein Einzel-Ingest ist schlicht ein
/// `WorkBasket` mit einem Pick; kein neuer Container. Bewusst ein typealias,
/// damit die Naht keinen zweiten Warenkorb-Begriff einführt.
public typealias CheckInGegenstand = WorkBasket

// MARK: - AuditKanal

/// Der grobe Audit-Kanal, den ein Adapter für seinen Vorgang deklariert. Bildet
/// 1:1 auf `AuditEntry.Action` ab — der Adapter klassifiziert, die Spine baut den
/// finalen `AuditEntry`. Der Kanal bleibt grob (das geschlossene Action-Enum);
/// die feine Herkunft trägt `CheckInAbsicht.quelle` als offener String.
public enum AuditKanal: Sendable, Equatable {
    /// Eingegangenes Angebot in Review übernommen (CashWidget-Naht).
    case angebotImportiert
    /// Warenkorb-Version versendet/abgelegt (CartStore-Naht).
    case warenkorbGesendet
    /// Kalibrierungs-/Schätz-Anpassung bestätigt (Kalkulations-Naht).
    case schaetzungAngepasst
    /// Generischer Checkout-Ausgang (Sevdesk-Postbox u. a. künftige Ports).
    case checkoutAusgefuehrt

    /// Übersetzung in das geschlossene `AuditEntry.Action`-Enum. Ein neuer Kanal
    /// verlangt hier eine bewusste Entscheidung — das Enum bleibt zu, die offene
    /// Herkunft läuft über `quelle`.
    public var auditAction: AuditEntry.Action {
        switch self {
        case .angebotImportiert:   return .offerImported
        case .warenkorbGesendet:   return .warenkorbGesendet
        case .schaetzungAngepasst: return .estimateAdjusted
        case .checkoutAusgefuehrt: return .warenkorbGesendet
        }
    }
}

// MARK: - CheckInAbsicht

/// „was/wohin/warum/WER" — die Absicht eines Check-ins. Trägt den Ziel-Adapter,
/// das Ziel, die Begründung, den PFLICHT-Nutzerstempel (`actorUserID`, nie leer),
/// den Projektbezug und die offene Herkunft (`quelle`).
public struct CheckInAbsicht: Sendable {
    /// Welcher Adapter (Schlüssel im Registry + Rechte-Gate).
    public let adapterID: PortID
    /// Wohin (port-spezifische Zieladresse).
    public let ziel: PortZiel
    /// Warum → landet in `AuditEntry.summary`.
    public let begruendung: String
    /// WER — der bestätigende Mensch. Pflichtfeld. Quelle: `AppState.actorUserID`.
    public let actorUserID: String
    /// Projektbezug → `AuditEntry.projectID` (bei nil = "-").
    public let projektNummer: String?
    /// Offene Herkunft (z. B. "drive-offer", "kalkulation", "warenkorb"). Landet in
    /// `AuditEntry.quelle`.
    public let quelle: String?

    public init(
        adapterID: PortID,
        ziel: PortZiel,
        begruendung: String,
        actorUserID: String,
        projektNummer: String? = nil,
        quelle: String? = nil
    ) {
        self.adapterID = adapterID
        self.ziel = ziel
        self.begruendung = begruendung
        self.actorUserID = actorUserID
        self.projektNummer = projektNummer
        self.quelle = quelle
    }
}

// MARK: - CheckInVorschau

/// Vorschau (schreibt nie). Trägt die bestehende `CheckoutPreview` UNVERÄNDERT
/// plus die Spine-Additive: den deterministischen Idempotenz-Schlüssel und die
/// Duplikat-Erkennung.
public struct CheckInVorschau: Sendable {
    /// Die bestehende Checkout-Vorschau — wiederbenutzt, nicht ersetzt.
    public let vorschau: CheckoutPreview
    /// Deterministischer Dedup-Schlüssel (SHA/Hash — NIE Date()/UUID()).
    public let idempotenzSchluessel: String
    /// Schon eingecheckt? → `bestaetigen` schreibt keinen zweiten Audit.
    public let istDuplikat: Bool

    public init(
        vorschau: CheckoutPreview,
        idempotenzSchluessel: String,
        istDuplikat: Bool
    ) {
        self.vorschau = vorschau
        self.idempotenzSchluessel = idempotenzSchluessel
        self.istDuplikat = istDuplikat
    }
}

// MARK: - CheckInAusfuehrung

/// Roh-Ergebnis eines Adapters: das bestehende `CheckoutResult` plus die
/// Klassifikation (Kanal) + optionaler Summary-Detail. Der Adapter liefert das
/// Roh-Ergebnis, die SPINE baut daraus den finalen `AuditEntry` — so kann kein
/// Adapter das Audit „vergessen".
public struct CheckInAusfuehrung: Sendable {
    /// Das bestehende Checkout-Ergebnis — unverändert.
    public let ergebnis: CheckoutResult
    /// Grober Audit-Kanal (→ `AuditEntry.Action`).
    public let kanal: AuditKanal
    /// Optionaler Zusatztext für die Summary (an die Begründung angehängt).
    public let summaryDetail: String?

    public init(
        ergebnis: CheckoutResult,
        kanal: AuditKanal,
        summaryDetail: String? = nil
    ) {
        self.ergebnis = ergebnis
        self.kanal = kanal
        self.summaryDetail = summaryDetail
    }
}

// MARK: - CheckInQuittung

/// Quittung eines bestätigten Check-ins: das `CheckoutResult` plus der von der
/// SPINE geschriebene `AuditEntry` (nicht vom Adapter).
public struct CheckInQuittung: Sendable {
    /// Das Checkout-Ergebnis — unverändert.
    public let ergebnis: CheckoutResult
    /// Der zentral von der Spine geschriebene Audit-Eintrag.
    public let audit: AuditEntry

    public init(ergebnis: CheckoutResult, audit: AuditEntry) {
        self.ergebnis = ergebnis
        self.audit = audit
    }
}

// MARK: - CheckInFehler

/// Fehler der Spine-Orchestrierung (getrennt von Adapter-internen Fehlern).
public enum CheckInFehler: Error, Equatable, Sendable {
    /// Kein Adapter mit dieser ID im Registry.
    case adapterUnbekannt(PortID)
    /// Der Rechte-Provider erlaubt diesem User den Adapter nicht.
    case keinRecht(PortID)
    /// Der Adapter verarbeitet die Inhalts-Art des Gegenstands nicht.
    case inhaltsArtNichtErlaubt(PortID, InhaltsArt)
}

// MARK: - CheckInAdapter

/// Das EINE Adapter-Protokoll — ein echtes Superset der `CheckoutPort`-Fähigkeit,
/// aber `CheckoutPort` bleibt UNBERÜHRT. Ein trivialer Brücken-Wrapper
/// (`CheckoutPortAsCheckInAdapter`) macht aus jedem bestehenden `CheckoutPort`
/// einen `CheckInAdapter`, ohne die Ports zu ändern.
///
/// WICHTIG: `fuehreAus` schreibt NIEMALS selbst das Audit. Es liefert nur das
/// Roh-Ergebnis + die Klassifikation; die Spine baut + schreibt den `AuditEntry`
/// zentral.
public protocol CheckInAdapter: Sendable {
    /// Stabiler Adapter-Bezeichner (Schlüssel im Registry + Rechte-Gate).
    var id: PortID { get }
    /// Menschenlesbarer Name.
    var name: String { get }
    /// Welche Inhalts-Arten dieser Adapter verarbeitet.
    func erlaubteInhaltsArten() -> Set<InhaltsArt>
    /// Deterministischer Idempotenz-Schlüssel (Muster: SevdeskPostboxCheckoutPort.objektHash).
    /// NIE Date()/UUID() — sonst ist Idempotenz gebrochen.
    func idempotenzSchluessel(_ gegenstand: CheckInGegenstand, _ absicht: CheckInAbsicht) -> String
    /// Schreibt NICHTS; liefert Vorschau. `istDuplikat` darf der Adapter selbst
    /// bestimmen (Port-eigene Idempotenz); Default in der Brücke ist `false`.
    func vorschau(_ gegenstand: CheckInGegenstand, _ absicht: CheckInAbsicht) async throws -> CheckInVorschau
    /// Führt aus (append-only). Liefert Roh-Ergebnis + Kanal; schreibt das Audit NICHT.
    func fuehreAus(_ gegenstand: CheckInGegenstand, _ absicht: CheckInAbsicht) async throws -> CheckInAusfuehrung
}

// MARK: - CheckInAuditSink

/// Injizierbare Audit-Senke (modul-sauber, analog `PortRightsProviding`). Das
/// Protokoll lebt hier in MykilosKit (Foundation-only); die konkrete
/// Implementierung wrappt den bestehenden `AuditStore` in MykilosServices.
public protocol CheckInAuditSink: Sendable {
    /// Schreibt EINEN Audit-Eintrag (throws, append-only, SaveState im Store sichtbar).
    func schreibe(_ entry: AuditEntry) async throws
}

// MARK: - CheckInSpine

/// Der Orchestrator: zwei Schritte, die Review→Audit erzwingen. Zentral auditiert,
/// idempotent, Rechte zweifach geprüft (nicht der UI vertrauen).
public struct CheckInSpine: Sendable {
    /// Alle andockbaren Adapter, nach ID.
    private let adapter: [PortID: any CheckInAdapter]
    /// Rechte-Quelle (heute `AllowAllPortRights`; echter Provider kommt später ohne Naht-Änderung).
    private let rechte: any PortRightsProviding
    /// Zentrale Audit-Senke (wrappt den bestehenden AuditStore).
    private let audit: any CheckInAuditSink

    public init(
        adapter: [any CheckInAdapter],
        rechte: any PortRightsProviding,
        audit: any CheckInAuditSink
    ) {
        var byID: [PortID: any CheckInAdapter] = [:]
        for eintrag in adapter { byID[eintrag.id] = eintrag }
        self.adapter = byID
        self.rechte = rechte
        self.audit = audit
    }

    /// Alle registrierten Adapter-IDs (praktisch für `AllowAllPortRights`).
    public var alleAdapterIDs: Set<PortID> { Set(adapter.keys) }

    // MARK: Schritt 1 — vorschlagen (schreibt NIE)

    /// Prüft Recht + Inhalts-Art (wirft sonst), liefert die Vorschau des Adapters.
    /// Schreibt weder Audit noch Ziel — reine Vorschau.
    public func vorschlagen(
        _ gegenstand: CheckInGegenstand,
        _ absicht: CheckInAbsicht
    ) async throws -> CheckInVorschau {
        let zielAdapter = try pruefeUndHole(absicht, inhaltsArt: gegenstand.inhaltsArt)
        return try await zielAdapter.vorschau(gegenstand, absicht)
    }

    // MARK: Schritt 2 — bestaetigen (nach menschlichem Klick)

    /// Prüft das Recht ERNEUT (nicht der UI vertrauen), führt aus, baut + schreibt
    /// den `AuditEntry` ZENTRAL. Bei `istDuplikat == true`: kein zweiter Write, aber
    /// Erfolg zurück (Idempotenz — der bestehende Audit gilt als Quittung).
    public func bestaetigen(
        _ gegenstand: CheckInGegenstand,
        _ absicht: CheckInAbsicht
    ) async throws -> CheckInQuittung {
        let zielAdapter = try pruefeUndHole(absicht, inhaltsArt: gegenstand.inhaltsArt)

        // Vorschau erneut, um die Duplikat-Erkennung + den deterministischen Key zu bekommen.
        let vorschau = try await zielAdapter.vorschau(gegenstand, absicht)

        if vorschau.istDuplikat {
            // Idempotenz: kein zweiter Write. Erfolg mit dem bestehenden Key als Referenz.
            let quittungOhneNeuenWrite = CheckoutResult(
                erfolg: true,
                referenz: vorschau.idempotenzSchluessel,
                meldung: "Bereits eingecheckt (Duplikat) — kein zweiter Audit."
            )
            let audit = baueAudit(
                absicht: absicht,
                kanal: .checkoutAusgefuehrt,
                summaryDetail: "Duplikat — bestehender Eintrag gilt",
                idempotenzKey: vorschau.idempotenzSchluessel
            )
            // KEIN schreibe(...) — genau EIN Audit über beide Läufe.
            return CheckInQuittung(ergebnis: quittungOhneNeuenWrite, audit: audit)
        }

        let ausfuehrung = try await zielAdapter.fuehreAus(gegenstand, absicht)
        let entry = baueAudit(
            absicht: absicht,
            kanal: ausfuehrung.kanal,
            summaryDetail: ausfuehrung.summaryDetail,
            idempotenzKey: vorschau.idempotenzSchluessel
        )
        try await audit.schreibe(entry)
        return CheckInQuittung(ergebnis: ausfuehrung.ergebnis, audit: entry)
    }

    // MARK: - Intern

    /// Zweifache Prüfung: Adapter existiert · User-Recht · Inhalts-Art-Gate.
    private func pruefeUndHole(
        _ absicht: CheckInAbsicht,
        inhaltsArt: InhaltsArt
    ) throws -> any CheckInAdapter {
        guard let zielAdapter = adapter[absicht.adapterID] else {
            throw CheckInFehler.adapterUnbekannt(absicht.adapterID)
        }
        let erlaubt = rechte.erlaubtePorts(userID: absicht.actorUserID)
        guard erlaubt.contains(absicht.adapterID) else {
            throw CheckInFehler.keinRecht(absicht.adapterID)
        }
        guard zielAdapter.erlaubteInhaltsArten().contains(inhaltsArt) else {
            throw CheckInFehler.inhaltsArtNichtErlaubt(absicht.adapterID, inhaltsArt)
        }
        return zielAdapter
    }

    /// Baut den finalen `AuditEntry` aus der Absicht + der Adapter-Klassifikation.
    /// Der Nutzerstempel kommt aus der Absicht (Pflichtfeld), nie hartkodiert.
    private func baueAudit(
        absicht: CheckInAbsicht,
        kanal: AuditKanal,
        summaryDetail: String?,
        idempotenzKey: String
    ) -> AuditEntry {
        let summary: String
        if let detail = summaryDetail, detail.isEmpty == false {
            summary = "\(absicht.begruendung) — \(detail)"
        } else {
            summary = absicht.begruendung
        }
        return AuditEntry(
            actorUserID: absicht.actorUserID,
            projectID: absicht.projektNummer ?? "-",
            action: kanal.auditAction,
            summary: summary,
            quelle: absicht.quelle,
            idempotenzKey: idempotenzKey
        )
    }
}
