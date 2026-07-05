import Testing
import Foundation
@testable import MykilosKit

// MARK: - CheckInSpineTests
// Die CheckIn-Naht, rein in-memory (Foundation-only, kein GRDB/Netz/Keychain).
// Beweist: vorschlagen() schreibt nie · bestaetigen() schreibt genau 1 · Duplikat → 0 weitere ·
// Rechte-Gate greift zweifach · Brücke ruft preview/execute korrekt durch.

struct CheckInSpineTests {

    // MARK: - Test-Doubles

    /// Zählende Audit-Senke: merkt sich jede geschriebene AuditEntry.
    private final class ZaehlSink: CheckInAuditSink, @unchecked Sendable {
        private(set) var geschrieben: [AuditEntry] = []
        func schreibe(_ entry: AuditEntry) async throws {
            geschrieben.append(entry)
        }
    }

    /// Fake-Adapter: execute NUR in fuehreAus, nie in vorschau. Zählt beide Aufrufe.
    /// `istDuplikat` steuerbar, um die Idempotenz-Verzweigung zu prüfen.
    private final class FakeAdapter: CheckInAdapter, @unchecked Sendable {
        let id: PortID
        let name: String
        let arten: Set<InhaltsArt>
        let duplikat: Bool
        private(set) var vorschauAufrufe = 0
        private(set) var fuehreAusAufrufe = 0

        init(id: PortID, arten: Set<InhaltsArt>, duplikat: Bool = false) {
            self.id = id
            self.name = "Fake \(id.raw)"
            self.arten = arten
            self.duplikat = duplikat
        }

        func erlaubteInhaltsArten() -> Set<InhaltsArt> { arten }

        func idempotenzSchluessel(_ g: CheckInGegenstand, _ a: CheckInAbsicht) -> String {
            "IDEMP-\(id.raw)-\(g.id.raw)"
        }

        func vorschau(_ g: CheckInGegenstand, _ a: CheckInAbsicht) async throws -> CheckInVorschau {
            vorschauAufrufe += 1
            return CheckInVorschau(
                vorschau: CheckoutPreview(zusammenfassung: "vorschau \(id.raw)"),
                idempotenzSchluessel: idempotenzSchluessel(g, a),
                istDuplikat: duplikat
            )
        }

        func fuehreAus(_ g: CheckInGegenstand, _ a: CheckInAbsicht) async throws -> CheckInAusfuehrung {
            fuehreAusAufrufe += 1
            return CheckInAusfuehrung(
                ergebnis: CheckoutResult(erfolg: true, referenz: id.raw),
                kanal: .angebotImportiert,
                summaryDetail: "detail"
            )
        }
    }

    /// Rechte-Provider, der genau eine PortID verbietet.
    private struct VerbietetEinen: PortRightsProviding {
        let alle: Set<PortID>
        let verboten: PortID
        func erlaubtePorts(userID: String) -> Set<PortID> { alle.subtracting([verboten]) }
    }

    private func gegenstand() -> CheckInGegenstand {
        WorkBasket(
            id: WorkBasketID("WK-2026-015-0001"),
            projektNummer: "2026-015",
            inhaltsArt: .artikel
        )
    }

    private func absicht(_ id: PortID) -> CheckInAbsicht {
        CheckInAbsicht(
            adapterID: id,
            ziel: PortZiel(kind: "postbox"),
            begruendung: "Angebot in Review",
            actorUserID: "johannes@example.com",
            projektNummer: "2026-015",
            quelle: "drive-offer"
        )
    }

    private func spine(_ adapter: [any CheckInAdapter], _ sink: ZaehlSink,
                       rechte: (any PortRightsProviding)? = nil) -> CheckInSpine {
        let ids = Set(adapter.map(\.id))
        return CheckInSpine(
            adapter: adapter,
            rechte: rechte ?? AllowAllPortRights(alleBekanntenPorts: ids),
            audit: sink
        )
    }

    // MARK: - 1. vorschlagen() schreibt NIE

    @Test func vorschlagenSchreibtKeinAudit() async throws {
        let a = FakeAdapter(id: PortID("cash"), arten: [.artikel])
        let sink = ZaehlSink()
        let s = spine([a], sink)

        let vorschau = try await s.vorschlagen(gegenstand(), absicht(PortID("cash")))

        #expect(sink.geschrieben.isEmpty)          // 0 Writes
        #expect(a.fuehreAusAufrufe == 0)           // execute nie in vorschlagen
        #expect(vorschau.idempotenzSchluessel == "IDEMP-cash-WK-2026-015-0001")
    }

    // MARK: - 2. bestaetigen() schreibt GENAU 1 Audit

    @Test func bestaetigenSchreibtGenauEinAudit() async throws {
        let a = FakeAdapter(id: PortID("cash"), arten: [.artikel])
        let sink = ZaehlSink()
        let s = spine([a], sink)

        let quittung = try await s.bestaetigen(gegenstand(), absicht(PortID("cash")))

        #expect(sink.geschrieben.count == 1)
        #expect(a.fuehreAusAufrufe == 1)
        // Nutzerstempel + Herkunft + Projekt landen im Audit (nicht hartkodiert).
        let entry = sink.geschrieben[0]
        #expect(entry.actorUserID == "johannes@example.com")
        #expect(entry.projectID == "2026-015")
        #expect(entry.quelle == "drive-offer")
        #expect(entry.action == .offerImported)          // kanal .angebotImportiert → .offerImported
        #expect(entry.idempotenzKey == "IDEMP-cash-WK-2026-015-0001")
        #expect(entry.summary == "Angebot in Review — detail")
        #expect(quittung.audit.id == entry.id)
    }

    // MARK: - 3. Duplikat → 0 weitere Writes (Idempotenz)

    @Test func duplikatSchreibtKeinZweitesAudit() async throws {
        let a = FakeAdapter(id: PortID("cash"), arten: [.artikel], duplikat: true)
        let sink = ZaehlSink()
        let s = spine([a], sink)

        let quittung = try await s.bestaetigen(gegenstand(), absicht(PortID("cash")))

        #expect(sink.geschrieben.isEmpty)     // KEIN Write bei Duplikat
        #expect(a.fuehreAusAufrufe == 0)      // execute wird bei Duplikat übersprungen
        #expect(quittung.ergebnis.erfolg)     // aber Erfolg zurück (Idempotenz-Quittung)
    }

    // MARK: - 4. Rechte-Gate greift (auch heute No-Op AllowAll ist prüfbar via Fake)

    @Test func rechteGateWirftWennVerboten() async throws {
        let a = FakeAdapter(id: PortID("cash"), arten: [.artikel])
        let sink = ZaehlSink()
        let rechte = VerbietetEinen(alle: [PortID("cash")], verboten: PortID("cash"))
        let s = spine([a], sink, rechte: rechte)

        await #expect(throws: CheckInFehler.keinRecht(PortID("cash"))) {
            _ = try await s.bestaetigen(gegenstand(), absicht(PortID("cash")))
        }
        #expect(sink.geschrieben.isEmpty)   // kein Audit bei fehlendem Recht
    }

    // MARK: - 5. Unbekannter Adapter wirft

    @Test func unbekannterAdapterWirft() async throws {
        let a = FakeAdapter(id: PortID("cash"), arten: [.artikel])
        let sink = ZaehlSink()
        let s = spine([a], sink)

        await #expect(throws: CheckInFehler.adapterUnbekannt(PortID("nichtda"))) {
            _ = try await s.bestaetigen(gegenstand(), absicht(PortID("nichtda")))
        }
    }

    // MARK: - 6. Inhalts-Art-Gate wirft

    @Test func inhaltsArtGateWirft() async throws {
        // Adapter kann NUR bilder, Gegenstand ist artikel.
        let a = FakeAdapter(id: PortID("moodboard"), arten: [.bilder])
        let sink = ZaehlSink()
        let s = spine([a], sink)

        await #expect(throws: CheckInFehler.inhaltsArtNichtErlaubt(PortID("moodboard"), .artikel)) {
            _ = try await s.bestaetigen(gegenstand(), absicht(PortID("moodboard")))
        }
        #expect(sink.geschrieben.isEmpty)
    }

    // MARK: - 7. Brücke: CheckoutPort → CheckInAdapter, execute erst in fuehreAus

    /// Zähl-Port: merkt sich preview/execute-Aufrufe.
    private final class ZaehlPort: MykilosKit.CheckoutPort, @unchecked Sendable {
        let id: PortID
        let name: String
        let arten: Set<InhaltsArt>
        private(set) var previewAufrufe = 0
        private(set) var executeAufrufe = 0

        init(id: PortID, arten: Set<InhaltsArt>) {
            self.id = id; self.name = "Zaehl \(id.raw)"; self.arten = arten
        }

        func erlaubteInhaltsArten() -> Set<InhaltsArt> { arten }
        func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview {
            previewAufrufe += 1
            return CheckoutPreview(zusammenfassung: "preview \(id.raw)")
        }
        func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult {
            executeAufrufe += 1
            return CheckoutResult(erfolg: true, referenz: id.raw)
        }
    }

    @Test func brueckeRuftPreviewUndExecuteKorrektDurch() async throws {
        let port = ZaehlPort(id: PortID("sevdesk"), arten: [.artikel])
        let bruecke = CheckoutPortAsCheckInAdapter(port: port)

        // vorschau → nur preview, kein execute.
        let v = try await bruecke.vorschau(gegenstand(), absicht(PortID("sevdesk")))
        #expect(port.previewAufrufe == 1)
        #expect(port.executeAufrufe == 0)
        #expect(v.istDuplikat == false)
        #expect(v.idempotenzSchluessel.isEmpty == false)

        // fuehreAus → execute.
        let aus = try await bruecke.fuehreAus(gegenstand(), absicht(PortID("sevdesk")))
        #expect(port.executeAufrufe == 1)
        #expect(aus.ergebnis.erfolg)
        #expect(aus.kanal == .checkoutAusgefuehrt)
    }

    // MARK: - 8. Idempotenz-Schlüssel ist deterministisch (kein Date/UUID)

    @Test func idempotenzSchluesselDeterministischUeberWiederholung() {
        let port = ZaehlPort(id: PortID("sevdesk"), arten: [.artikel])
        let bruecke = CheckoutPortAsCheckInAdapter(port: port)
        let g = gegenstand()
        let a = absicht(PortID("sevdesk"))
        let k1 = bruecke.idempotenzSchluessel(g, a)
        let k2 = bruecke.idempotenzSchluessel(g, a)
        #expect(k1 == k2)                 // reproduzierbar
        #expect(k1.isEmpty == false)
        // FNV-Hash ist stabil über Instanzen.
        #expect(CheckInHash.stabil("abc") == CheckInHash.stabil("abc"))
        #expect(CheckInHash.stabil("abc") != CheckInHash.stabil("abd"))
    }
}
