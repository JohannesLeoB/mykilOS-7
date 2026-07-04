import Foundation
import MykilosKalkulationsCore

// MARK: - feat/tischler-predictor · Phase 1 (B-gated)
// Macht das Schätz-Brain selbstwachsend: bestätigte EINGEHENDE Lieferanten-Angebote
// werden — hinter einem menschlichen Review-Gate — zu Preis-Ankern, die `schaetze`
// direkt liest. Drei Schutzschalter sind nicht verhandelbar:
//
//   1. Nur EINGEHEND (Lieferant → MYKILOS) wird Kostenanker. Ausgehende Angebote
//      (MYKILOS → Kunde) enthalten die eigene Marge und dürfen den Kostenboden NIE
//      anheben — sie gehören in einen getrennten Marktkanal (nicht Phase 1).
//   2. Nur NETTO. `nettoEur` ist bereits netto; es findet keine Brutto/Netto-Mischung
//      statt.
//   3. Nur REVIEW-BESTÄTIGT. Ein importierter Sync-Eintrag ist erst dann ein Anker,
//      wenn ein Mensch ihn über eine `ReviewAction` (kind `.releaseAsActiveAnchor`)
//      freigegeben hat. Der `LearnedAnchorProvider` liest ausschließlich freigegebene.
//
// Dazu kommt die Zeitgewichtung (`OfferAnchorInflation`): ältere Angebotspreise werden
// auf Gegenwartswert gehoben, damit die Teuerung 2021–23 nicht als „günstig" gelernt
// wird. Sie lebt bewusst HIER im gelernten Kanal — der geschützte EvidenceBasedEstimator
// (Offline-Backtest, ~8 %) bleibt unangetastet; der destillierte Seed-Korpus ist bereits
// gegenwartsnormiert.
//
// Bewusste Phase-1-Grobheit (siehe Handoff): ein bestätigtes Angebot ist ein WHOLE-OFFER-
// Gesamtbetrag → es wird als `aggregateKitchen`-Anker (Gesamt-Plausibilität) modelliert,
// NICHT positionsweise normalisiert. Die positionsweise Zerlegung (Schubkasten-Anzahl ×
// Variante, €/m²-Front-Bänder) ist Phase 2.

// Live-Anschluss (Adapter steht, Live-Fetch bewusst NOCH NICHT verdrahtet): Das echte
// Schema der Tabelle `Eingehende-Angebote` (tbliKfs5FnufjdB36) ist am 2026-06-29
// verifiziert (Felder: SHA256/Datei-Name/Projekt-Nr/Richtung/Kategorie/Lieferant/
// Netto-Summe/Anker-Anzahl/Status/Lern-Gewicht/Importiert-am; Tabelle leer, 0 Zeilen).
// `IncomingOfferRecordMapper` ist die getestete, netzwerkfreie Naht: Records →
// `[AirtableOfferEntry]` → `syncAirtableOffers(_:)`. Zwei ehrliche Lücken bleiben (siehe
// Mapper): `Status` ist ein WORKFLOW-Status ohne Geschäftsausgang (→ Promotion nur via
// menschliches Review-Gate, nie automatisch) und es gibt kein Angebotsdatum (nur
// „Importiert-am"). Kein spekulativer Live-Fetch gegen eine leere Tabelle.

// MARK: - Zeitgewichtung
// Hebt einen historischen Netto-Preis auf Gegenwartswert und liefert einen Konfidenz-
// Abschlag fürs Alter. Bewusst einfach und dokumentiert: eine jährliche Teuerung (CAGR)
// vom Angebotsjahr bis zum Bezugsjahr, gekappt; plus lineare Konfidenz-Degradation.
public enum OfferAnchorInflation {
    /// Jährliche Teuerung für Tischler-/Möbelbau (konservativ). Kein Anspruch auf
    /// amtliche Präzision — Ziel ist nur, alte Preise nicht fälschlich als billig zu lernen.
    public static let annualRate = 0.04
    /// Älter als so viele Jahre → maximaler (gekappter) Hebel; verhindert Übersteuern.
    public static let maxYears = 6

    /// Jahr aus einem rohen Airtable-Datumstext (tolerant: erstes 19xx/20xx).
    /// Bewusst ohne Regex (kein stilles Optional-Schlucken): ein einfacher Vierer-Ziffern-Scan.
    public static func year(from raw: String?) -> Int? {
        guard let raw else { return nil }
        let digits = Array(raw)
        for start in 0...(max(0, digits.count - 4)) where start + 4 <= digits.count {
            let window = digits[start..<start + 4]
            guard window.allSatisfy(\.isNumber) else { continue }
            let value = Int(String(window)) ?? 0
            if value >= 1900 && value <= 2100 { return value }
        }
        return nil
    }

    /// Inflationsfaktor vom Angebotsjahr auf das Bezugsjahr (≥ 1.0). Unbekanntes/zukünftiges
    /// Jahr → 1.0 (keine Anhebung, dafür Konfidenz-Abschlag, siehe `confidenceFactor`).
    public static func factor(offerYear: Int?, referenceYear: Int) -> Decimal {
        guard let offerYear, offerYear < referenceYear else { return 1 }
        let years = min(referenceYear - offerYear, maxYears)
        let grown = pow(1 + annualRate, Double(years))
        return Decimal(grown)
    }

    /// Konfidenz-Abschlag fürs Alter (1.0 = frisch). Unbekanntes Datum wird wie „alt"
    /// behandelt — wir wissen nicht, ob der Preis aktuell ist.
    public static func confidenceFactor(offerYear: Int?, referenceYear: Int) -> Double {
        guard let offerYear else { return 0.7 }
        let years = max(0, min(referenceYear - offerYear, maxYears))
        return max(0.55, 1 - Double(years) * 0.06)
    }
}

// MARK: - LearningStore: Anker-Schreibpfad + Review-Gate (append-only)
public extension LearningStore {

    /// Konfidenz-Basiswert je Lerngrund — Schlussrechnung schlägt Angebot.
    internal static func baseConfidence(for reason: EstimateAdjustmentReason) -> Double {
        switch reason {
        case .finalInvoiceReceived: return 0.9
        case .realOfferReceived:    return 0.75
        default:                    return 0.6
        }
    }

    /// Schritt 1+2+5: abgeschlossene Angebote nach `airtable_offer_sync` schreiben.
    /// Filter: nur EINGEHEND mit gültigem `learningReason` wird Kostenanker (Schlussrechnung
    /// 2,0× / akzeptiert 1,6×). Dedup über `airtableRecordID UNIQUE`. Append-only:
    /// jeder Eintrag landet als `syncStatus = "imported"` (Review steht noch aus).
    @discardableResult
    func syncAirtableOffers(_ offers: [AirtableOfferEntry]) throws -> AirtableOfferSyncReport {
        let learningDB = try database()
        var imported = 0, skippedDuplicate = 0, skippedNoSignal = 0
        var errors: [String] = []

        for offer in offers {
            // Schutzschalter: ausgehend ODER ohne Lerngrund → kein Kostenanker.
            guard offer.kind == .eingehend, offer.status.learningReason(kind: offer.kind) != nil else {
                skippedNoSignal += 1
                continue
            }
            do {
                if try learningDB.airtableRecordIDExists(offer.airtableRecordID) {
                    skippedDuplicate += 1
                    continue
                }
                let entry = AirtableOfferSyncEntry(
                    airtableRecordID: offer.airtableRecordID,
                    offerKind: offer.kind,
                    nettoEur: offer.nettoEur,
                    offerStatus: offer.status,
                    partner: offer.partner,
                    docSHA256: nil,
                    reviewActionID: nil,
                    syncStatus: "imported",
                    offerDate: offer.datum
                )
                try learningDB.write { conn in
                    try learningDB.insert(entry, conn)
                    try learningDB.insert(
                        LearningAuditLogEntry(
                            entityID: entry.id,
                            entityTable: "airtable_offer_sync",
                            action: "offer_imported",
                            message: "Eingehendes Angebot \(offer.partner) (netto \(offer.nettoEur)) importiert — Review steht aus."
                        ),
                        conn
                    )
                }
                imported += 1
            } catch {
                errors.append("\(offer.airtableRecordID): \(error)")
            }
        }
        return AirtableOfferSyncReport(
            fetched: offers.count,
            skippedDuplicate: skippedDuplicate,
            skippedNoSignal: skippedNoSignal,
            imported: imported,
            errors: errors
        )
    }

    /// Schritt 3 (menschliches Gate): einen importierten Sync-Eintrag freigeben. Schreibt
    /// eine `ReviewAction` (`.releaseAsActiveAnchor`, append-only) + Audit. Erst danach
    /// liest ihn der `LearnedAnchorProvider`. `candidateID` ist die `airtableRecordID`.
    @discardableResult
    func confirmOfferAnchor(airtableRecordID: String, note: String = "") throws -> ReviewAction {
        let learningDB = try database()
        let action = ReviewAction(
            candidateID: airtableRecordID,
            kind: .releaseAsActiveAnchor,
            note: note
        )
        try learningDB.write { conn in
            try learningDB.insert(action, conn)
            try learningDB.insert(
                LearningAuditLogEntry(
                    entityID: airtableRecordID,
                    entityTable: "airtable_offer_sync",
                    action: "offer_confirmed",
                    message: "Angebot \(airtableRecordID) als Kostenanker freigegeben. \(note)"
                ),
                conn
            )
        }
        return action
    }

    /// Alle importierten Sync-Einträge (Append-Reihenfolge).
    func offerSyncEntries() throws -> [AirtableOfferSyncEntry] {
        try database().airtableOfferSyncEntries()
    }

    /// Airtable-Record-IDs, die ein menschliches Release tragen.
    func confirmedOfferRecordIDs() throws -> Set<String> {
        let actions = try database().reviewActions()
        return Set(actions.filter { $0.kind == .releaseAsActiveAnchor }.map(\.candidateID))
    }

    /// Noch nicht freigegebene Einträge (für die Review-/Action-Card-Liste).
    func pendingOfferSyncEntries() throws -> [AirtableOfferSyncEntry] {
        let confirmed = try confirmedOfferRecordIDs()
        return try offerSyncEntries().filter { !confirmed.contains($0.airtableRecordID) }
    }

    /// Review-bestätigte Einträge (Quelle des LearnedAnchorProvider).
    func confirmedOfferSyncEntries() throws -> [AirtableOfferSyncEntry] {
        let confirmed = try confirmedOfferRecordIDs()
        return try offerSyncEntries().filter { confirmed.contains($0.airtableRecordID) }
    }
}

// MARK: - LearnedAnchorProvider
// Schritt 4: liest NUR review-bestätigte eingehende Angebote und macht aus jedem einen
// gegenwartsnormierten `aggregateKitchen`-Anker. Liefert KEINE unbestätigten Einträge —
// das Gate lebt in der Datenquelle, nicht in der UI.
public struct LearnedAnchorProvider: PriceAnchorProviding {
    private let store: LearningStore
    private let referenceYear: Int

    public init(store: LearningStore, referenceYear: Int? = nil) {
        self.store = store
        self.referenceYear = referenceYear ?? Calendar(identifier: .gregorian).component(.year, from: Date())
    }

    public func activeAnchors() throws -> [CandidateReleaseDecision] {
        try store.confirmedOfferSyncEntries().compactMap { entry in
            guard entry.nettoEur > 0 else { return nil }
            guard let reason = entry.offerStatus.learningReason(kind: entry.offerKind) else { return nil }

            let offerYear = OfferAnchorInflation.year(from: entry.offerDate)
            let inflation = OfferAnchorInflation.factor(offerYear: offerYear, referenceYear: referenceYear)
            let presentValue = entry.nettoEur * inflation
            let confidence = LearningStore.baseConfidence(for: reason)
                * OfferAnchorInflation.confidenceFactor(offerYear: offerYear, referenceYear: referenceYear)

            // Neutraler Beleg-Text: KEINE Carryforward-verbotenen Begriffe (Summe/Gesamtbetrag/
            // Nettobetrag/MwSt …), sonst filtert der Estimator den Anker als Übertrags-Risiko.
            let jahr = offerYear.map(String.init) ?? "o. J."
            let quote = "Bestätigtes eingehendes Angebot \(entry.partner), \(jahr), netto \(presentValue) EUR (gegenwartsnormiert)."

            return CandidateReleaseDecision(
                candidateID: "LEARNED-\(entry.airtableRecordID)",
                sourceFile: "Airtable · Eingehende-Angebote",
                page: 0,
                supplier: entry.partner,
                project: "",
                component: "Gesamtküche \(entry.partner)",
                trade: reason.displayName,
                priceNetGuess: presentValue,
                confidence: confidence,
                duplicateCount: 0,
                currentStatus: "release_candidate",
                proposedStatus: "release_candidate",
                supersededBy: nil,
                decisionScore: confidence,
                decisionReason: "learned_incoming_offer",
                helpNeeded: "",
                title: "Eingehendes Angebot \(entry.partner)",
                evidenceQuote: quote,
                carryforwardRuleStatus: "",
                ruleSafePriceNet: nil,
                ruleNotes: "",
                componentClass: .aggregateKitchen,
                sourceKind: .pdfOffer
            )
        }
    }
}

// MARK: - CompositeAnchorProvider
// Schritt 4: legt den destillierten Seed-Korpus (BrainSeedProvider) und die gelernten,
// bestätigten Anker (LearnedAnchorProvider) übereinander. Reihenfolge: Seed zuerst, dann
// gelernt — der Estimator dedupliziert über `candidateID` nicht, aber die IDs sind
// disjunkt (`LEARNED-…`). Fällt der gelernte Kanal aus, bleibt der Seed allein funktional.
public struct CompositeAnchorProvider: PriceAnchorProviding {
    private let primary: PriceAnchorProviding
    private let learned: PriceAnchorProviding
    /// Optionaler dritter Kanal: lokal review-bestätigte PDF-Positionen (Lern-Loop).
    /// Wie der gelernte Kanal degradiert er bei Fehler still.
    private let pdfLearned: PriceAnchorProviding?

    public init(primary: PriceAnchorProviding, learned: PriceAnchorProviding,
                pdfLearned: PriceAnchorProviding? = nil) {
        self.primary = primary
        self.learned = learned
        self.pdfLearned = pdfLearned
    }

    public func activeAnchors() throws -> [CandidateReleaseDecision] {
        // Seed-Ausfall ist ein echter Fehler → werfen. Die gelernten Kanäle degradieren
        // dagegen bewusst still (do/catch statt stillem Optional-Schlucken): fällt das Gate/die
        // learning.sqlite aus, bleibt der Seed-Korpus allein funktional.
        let base = try primary.activeAnchors()
        return base + orEmpty(learned) + (pdfLearned.map(orEmpty) ?? [])
    }

    private func orEmpty(_ provider: PriceAnchorProviding) -> [CandidateReleaseDecision] {
        (try? provider.activeAnchors()) ?? []
    }
}
