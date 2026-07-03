import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - CashWidget
// Geld & Angebote. Tiefblau. Zwei Rollen:
//  1) Empfänger der Drive-Signale (DAS Widget, das die Signal-Kommunikation
//     zeigt: Drive flüstert, Cash fragt) — bewusst unabhängig von sevdesk,
//     damit der Architektur-Showcase auch ohne verbundenes sevdesk lebt.
//  2) Budget-Balken: Ist-Umsatz (Summe der sevdesk-Rechnungen für
//     Project.links.sevdeskRef) gegen das Soll-Budget (Project.links.budget,
//     Quelle Airtable). Reiner Lesefetch — mykilOS bucht nie in sevdesk.
public struct CashWidget: View {
    public let projectID: String
    public let sevdeskRef: String?
    public let budget: Double?
    public let auditStore: AuditStore?
    // Block H: optionale Quelle für die „kalkuliert"-Zeile (WorkBasket-Summe). Nil im
    // Home-/Nicht-Projekt-Kontext → Zeile bleibt aus, sevDesk-Verhalten unverändert.
    public let workBasketStore: WorkBasketStore?

    public init(
        projectID: String,
        sevdeskRef: String?,
        budget: Double?,
        auditStore: AuditStore? = nil,
        workBasketStore: WorkBasketStore? = nil
    ) {
        self.projectID = projectID
        self.sevdeskRef = sevdeskRef
        self.budget = budget
        self.auditStore = auditStore
        self.workBasketStore = workBasketStore
    }

    @Environment(StudioContext.self) private var context
    @State private var reviewAccepted = false
    @State private var auditError: String?
    @State private var loader = SevdeskInvoicesLoader()
    // Netto-VK-Summe des aktuellsten Projekt-WorkBaskets (0 = nichts kalkuliert).
    @State private var kalkuliertNetto: Double = 0

    /// Fester MwSt-Satz für die Brutto-Anzeige der kalkulierten Summe (deckt sich mit
    /// AngebotsRenderMapper.mwstSatz — hier lokal, weil Widgets MykilosApp nicht importieren).
    private static let mwstSatz = 0.19

    // Das echte Signal hinter "hasReviewSignal" — trägt den realen Angebotstext
    // (label) statt eines hartkodierten Platzhalters.
    private var reviewSignal: WidgetSignal? {
        context.signals(for: projectID).first {
            if case .reviewSuggested = $0 { return true }; return false
        }
    }

    private var hasReviewSignal: Bool { reviewSignal != nil }

    public var body: some View {
        WidgetContainer(
            kind: .cash,
            sourceLabel: sourceLabel,
            renderState: .content,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack { SourceChip(kind: .cash); Text("Angebote / Cash").mykWidgetTitle(); Spacer() }
                if kalkuliertNetto > 0 { kalkuliertZeile }
                if hasReviewSignal && !reviewAccepted {
                    signalPrompt
                } else {
                    budgetSection
                }
            }
        }
        .task(id: sevdeskRef) {
            await loader.load(contactRef: sevdeskRef)
            // Budget-Signal: echtes Monitoring (L22). Schwelle 70% → reviewSuggested-
            // Klasse; 90%+ → budgetThresholdCrossed-Signal für TodayView / FocusWidget.
            if let budget, budget > 0,
               loader.ist > 0 {
                let actual = loader.ist
                let ratio = actual / budget
                if ratio >= 0.9 {
                    context.emit(.budgetThresholdCrossed(projectID: projectID, ratio: ratio))
                }
            }
        }
        .task(id: projectID) {
            // Schon mal bestätigt (vor einem Neustart)? Dann nicht erneut als
            // "wartet auf Freigabe" zeigen — Quelle der Wahrheit ist der
            // persistierte Audit-Eintrag, nicht nur der lokale @State.
            reviewAccepted = auditStore?.entries.contains {
                $0.projectID == projectID && $0.action == .offerImported
            } ?? false
            // Block H: kalkulierte Warenkorb-Summe (nur sichtbar machen, kein Schreiben).
            if let workBasketStore {
                let baskets = (try? workBasketStore.alle(projektNummer: projectID)) ?? []
                kalkuliertNetto = baskets.max(by: { $0.erstellt < $1.erstellt })?.vkNettoSumme ?? 0
            }
        }
    }

    // MARK: - Block H: kalkulierte Warenkorb-Summe (schlanke Zeile)
    // Reine Sicht auf den am Projekt persistierten WorkBasket — unabhängig von sevDesk,
    // kein Budget-Balken, keine Schreibkette. sevDesk bleibt read-only (Ist-Umsatz).
    private var kalkuliertZeile: some View {
        HStack(spacing: MykSpace.s2) {
            Text("Kalkuliert (Warenkorb)")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
            Text("\(currency(kalkuliertNetto)) netto · \(currency(kalkuliertNetto * (1 + Self.mwstSatz))) brutto")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.cash.color)
        }
    }

    private var sourceLabel: String {
        let signalPart = hasReviewSignal && !reviewAccepted ? "WARTET AUF FREIGABE" : "AKTUELL"
        return "SEVDESK + DRIVE  ·  \(signalPart)"
    }

    // Das Signal-Prompt: Drive hat ein Angebot erkannt
    private var signalPrompt: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            // "Flüster"-Linie von Drive
            HStack(spacing: 8) {
                Rectangle().fill(MykColor.cash.color).frame(width: 16, height: 1.5)
                Text("DRIVE MELDET · NEUES EINGANGSANGEBOT")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.cash.color)
            }
            Text(signalText)
                .font(.mykSmall)
                .foregroundStyle(MykColor.ink.color)
            if let auditError {
                Text(auditError)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.critical.color)
            }
            Button {
                confirmReview()
            } label: {
                Text("In Review übernehmen →")
                    .font(.mykSmall).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.cash.color))
            }
            .buttonStyle(.plain)
        }
        .padding(MykSpace.s5)
        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.cash.color.opacity(0.08)))
    }

    // Der echte Signal-Text (label aus .reviewSuggested) statt eines für jedes
    // Projekt identischen, hartkodierten Platzhaltertexts.
    private var signalText: String {
        if case .reviewSuggested(_, let label) = reviewSignal {
            return "Drive-PDF erkannt — **\(label)**."
        }
        return "Drive-PDF erkannt."
    }

    // Bestätigung läuft über AuditStore.append(...) statt nur lokalen @State —
    // Schreibvorgänge kommen nie aus Views direkt, sondern über den Store, und
    // überleben jetzt einen Neustart (siehe .task(id: projectID) oben).
    private func confirmReview() {
        auditError = nil
        guard let auditStore else {
            withAnimation(.easeInOut(duration: 0.25)) { reviewAccepted = true }
            return
        }
        do {
            let entry = AuditEntry(
                actorUserID: "local-user",
                projectID: projectID,
                action: .offerImported,
                summary: signalText
            )
            try auditStore.append(entry)
            withAnimation(.easeInOut(duration: 0.25)) { reviewAccepted = true }
        } catch {
            auditError = "Konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Budget-Balken (Ist aus sevdesk vs. Soll aus Airtable)
    @ViewBuilder
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            if reviewAccepted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.positive.color)
                    Text("Angebot in Review übernommen").font(.mykSmall).foregroundStyle(MykColor.ink.color)
                }
            }
            switch loader.renderState {
            case .loading:
                inlineHint(icon: "hourglass", text: "Lade sevdesk-Umsatz …")
            case .permissionRequired:
                HStack {
                    inlineHint(icon: "lock", text: "sevdesk in den Einstellungen verbinden")
                    Spacer()
                    retryButton
                }
            case .error(let msg):
                HStack {
                    inlineHint(icon: "exclamationmark.triangle", text: msg)
                    Spacer()
                    retryButton
                }
            default:
                budgetBar
            }
        }
    }

    // Kein sevdesk-Bezug → reiner Soll-Wert; ohne Budget → Hinweis.
    @ViewBuilder
    private var budgetBar: some View {
        if let budget, budget > 0 {
            let ist = loader.ist
            let ratio = min(max(ist / budget, 0), 1)
            let overBudget = ist > budget
            VStack(alignment: .leading, spacing: MykSpace.s3) {
                HStack {
                    Text("Budget").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                    Spacer()
                    Text(percentText(ist: ist, budget: budget))
                        .font(.mykHeadline)
                        .foregroundStyle(overBudget ? MykColor.critical.color : MykColor.ink.color)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(MykColor.bone.color).frame(height: 4)
                        Capsule()
                            .fill(overBudget ? MykColor.critical.color : MykColor.cash.color)
                            .frame(width: geo.size.width * ratio, height: 4)
                    }
                }.frame(height: 4)
                HStack {
                    Text("\(currency(ist)) Ist").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                    Spacer()
                    Text("\(currency(budget)) Budget").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                }
            }
        } else if sevdeskRef != nil {
            inlineHint(icon: "eurosign.circle", text: "Kein Budget im Projekt hinterlegt")
        } else {
            inlineHint(icon: "tray", text: "Kein sevdesk-Kontakt verknüpft")
        }
    }

    private func inlineHint(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(MykColor.faint.color)
            Text(text).font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .lineLimit(2)
        }
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(contactRef: sevdeskRef) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.cash.color)
    }

    private func percentText(ist: Double, budget: Double) -> String {
        let pct = Int((ist / budget * 100).rounded())
        return "\(pct) %"
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

// MARK: - SevdeskInvoicesLoader
// Pro Widget-Instanz. Reiner Lesefetch des sevdesk-Umsatzes — kein Speichern-
// Vertrag wie bei NoteStore/WidgetBoardStore.
@MainActor
@Observable
private final class SevdeskInvoicesLoader {
    private(set) var ist: Double = 0
    private(set) var renderState: WidgetRenderState = .loading

    private let client: SevdeskFetching
    // Generation-Token: nur das jüngste load() committet (Projektwechsel/Retry).
    private var loadGeneration = 0

    init(client: SevdeskFetching = SevdeskClient()) {
        self.client = client
    }

    func load(contactRef: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let contactRef, contactRef.isEmpty == false else {
            ist = 0
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let invoices = try await client.invoices(contactRef: contactRef)
            guard generation == loadGeneration else { return }
            ist = invoices.reduce(0) { $0 + $1.sumGross }
            renderState = .content
        } catch SevdeskError.notConnected {
            guard generation == loadGeneration else { return }
            ist = 0
            renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            ist = 0
            renderState = .error(String(describing: error))
        }
    }
}
