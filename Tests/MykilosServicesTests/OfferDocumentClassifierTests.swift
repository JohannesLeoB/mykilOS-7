import Testing
import Foundation
@testable import MykilosServices

struct OfferDocumentClassifierTests {

    private func pdf(_ name: String) -> GoogleDriveFile {
        GoogleDriveFile(id: name, name: name, mimeType: "application/pdf", modifiedAt: nil, webViewLink: nil)
    }

    // MARK: - Präfix-Klassifikation (ausgehend)

    @Test func anPraefixWirdAngebot() {
        let r = OfferDocumentClassifier.classify(pdf("AN-A_2026-0151-Kdnr-12822_v3.pdf"), isIncoming: false)
        #expect(r.type == .angebot)
        #expect(r.belegNummer == "2026-0151")
        #expect(r.kundenNummer == "12822")
        #expect(r.version == "v3")
    }

    @Test func srPraefixWirdSchlussrechnung() {
        let r = OfferDocumentClassifier.classify(pdf("SR-SR_2026-0170-Kdnr-12822.pdf"), isIncoming: false)
        #expect(r.type == .schlussrechnung)
        #expect(r.belegNummer == "2026-0170")
        #expect(r.kundenNummer == "12822")
        #expect(r.version == nil)
    }

    @Test func trArePraefixWirdAbschlagsrechnung() {
        let r = OfferDocumentClassifier.classify(pdf("TR-ARE_2026-0123-Kdnr-12822.pdf"), isIncoming: false)
        #expect(r.type == .abschlagsrechnung)
        #expect(r.belegNummer == "2026-0123")
    }

    @Test func abPraefixWirdAuftrag() {
        let r = OfferDocumentClassifier.classify(pdf("AB-B_2026-0099-Kdnr-12822.pdf"), isIncoming: false)
        #expect(r.type == .auftrag)
    }

    @Test func unbekanntesPraefixAusgehendWirdSonstiges() {
        let r = OfferDocumentClassifier.classify(pdf("XYZ_irgendwas.pdf"), isIncoming: false)
        #expect(r.type == .sonstiges)
    }

    // MARK: - Eingehende Belege

    @Test func numerischerNameEingehendWirdEingehendesAngebot() {
        let r = OfferDocumentClassifier.classify(pdf("202603971.pdf"), isIncoming: true)
        #expect(r.type == .eingehendesAngebot)
    }

    @Test func eingehendIgnoriertAusgehendePraefixe() {
        // Selbst wenn ein eingehendes Dokument zufällig "AN" beginnt,
        // bleibt es eingehendesAngebot (nicht unser Angebot).
        let r = OfferDocumentClassifier.classify(pdf("ANGEBOT_Lieferant.pdf"), isIncoming: true)
        #expect(r.type == .eingehendesAngebot)
    }

    @Test func bestellPraefixEingehendWirdBestellung() {
        let r = OfferDocumentClassifier.classify(pdf("BE-2026-001.pdf"), isIncoming: true)
        #expect(r.type == .bestellung)
    }

    // MARK: - Extraktion

    @Test func extractPrefixNimmtErstesTokenGross() {
        #expect(OfferDocumentClassifier.extractPrefix(from: "AN-A_2026.pdf") == "AN")
        #expect(OfferDocumentClassifier.extractPrefix(from: "sr-sr_2026.pdf") == "SR")
        #expect(OfferDocumentClassifier.extractPrefix(from: "202603971.pdf") == "202603971")
    }

    @Test func extractKundenNummerOhneKdnrIstNil() {
        #expect(OfferDocumentClassifier.extractKundenNummer(from: "AN_2026-0151.pdf") == nil)
    }

    @Test func extractVersionOptional() {
        #expect(OfferDocumentClassifier.extractVersion(from: "AN_2026_v7.pdf") == "v7")
        #expect(OfferDocumentClassifier.extractVersion(from: "AN_2026.pdf") == nil)
    }

    // MARK: - Gruppierung-Reihenfolge

    @Test func anzeigeReihenfolgeStabil() {
        // rawValue bestimmt Sortierung: Angebot < Auftrag < Abschlag < Schluss
        #expect(OfferDocumentType.angebot.rawValue < OfferDocumentType.auftrag.rawValue)
        #expect(OfferDocumentType.auftrag.rawValue < OfferDocumentType.abschlagsrechnung.rawValue)
        #expect(OfferDocumentType.abschlagsrechnung.rawValue < OfferDocumentType.schlussrechnung.rawValue)
    }
}
