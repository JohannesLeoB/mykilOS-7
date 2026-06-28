import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - KalkulationsWidget
// Der Schätz-Brain. Gibt Min/Mitte/Max-Netto plus Konfidenz und Top-Evidenzen aus.
// Abhängigkeit nur über Protokoll — kein GRDB, kein direkter Store-Zugriff.
public struct KalkulationsWidget: View {
    public let projektID: String
    public let engine: any KalkulationsEngineProviding

    public init(projektID: String, engine: any KalkulationsEngineProviding) {
        self.projektID = projektID
        self.engine   = engine
    }

    @State private var freitext: String = ""
    @State private var state: KalkulationsRenderState = .empty

    // Anpassungs-Card (erscheint erst nach einer Schätzung)
    @State private var faktor: Double = 1.0
    @State private var grund: String = ""
    @State private var lernen: Bool = false
    @State private var adjustmentState: AdjustmentState = .idle

    // Lern-Loop sichtbar (ausklappbare Sektion)
    @State private var lernState: LernState = .loading
    @State private var lernExpanded: Bool = false
    @State private var promotingID: String?
    @State private var promoteBestaetigung: String?

    /// Die aktuell angezeigte Schätzung — Referenz für `recordAdjustment`.
    private var currentSchaetzung: KostenSchaetzung? {
        if case .content(let s) = state { return s }
        return nil
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
            sourceRow
        }
        .background(MykColor.paper2.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .stroke(MykColor.tasks.color.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: Hauptinhalt

    private var content: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            // Header
            HStack {
                SourceChip(kind: .kalkulation)
                Text("Kalkulation")
                    .mykWidgetTitle()
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                confidenceBadge
            }

            // Eingabefeld
            freitextField

            // Ergebnis-Bereich
            resultArea

            // Anpassung vorschlagen — nur nach einer Schätzung
            if let schaetzung = currentSchaetzung {
                Divider().overlay(MykColor.line.color)
                KalkulationsActionCard(
                    faktor: $faktor,
                    grund: $grund,
                    lernen: $lernen,
                    state: adjustmentState,
                    onConfirm: { await anpassen(schaetzung: schaetzung) }
                )
            }

            // Gelernte Kalibrierung — immer sichtbar (eigener Lese-Pfad, unabhängig
            // von einer laufenden Schätzung).
            Divider().overlay(MykColor.line.color)
            lernSektion
        }
        .padding(MykSpace.s6)
        .task { await ladeLernStand() }
    }

    // MARK: Gelernte Kalibrierung (ausklappbar)

    private var lernSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { lernExpanded.toggle() }
            } label: {
                HStack(spacing: MykSpace.s3) {
                    Image(systemName: lernExpanded ? "chevron.down" : "chevron.right")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                    Text("Gelernte Kalibrierung")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                    Spacer()
                    lernKopfzeile
                }
            }
            .buttonStyle(.plain)

            if lernExpanded {
                lernInhalt
            }
        }
    }

    // Kompakte Kennzahl rechts in der Kopfzeile (auch eingeklappt informativ).
    @ViewBuilder
    private var lernKopfzeile: some View {
        if case .content(let stand) = lernState, !stand.istLeer {
            HStack(spacing: MykSpace.s3) {
                if !stand.aktiveFaktoren.isEmpty {
                    Text("\(stand.aktiveFaktoren.count) aktiv")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.positive.color)
                }
                if !stand.kandidaten.isEmpty {
                    Text("\(stand.kandidaten.count) Kandidat\(stand.kandidaten.count == 1 ? "" : "en")")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.tasks.color)
                }
            }
        }
    }

    @ViewBuilder
    private var lernInhalt: some View {
        switch lernState {
        case .loading:
            HStack(spacing: MykSpace.s3) {
                ProgressView().controlSize(.small).tint(MykColor.tasks.color)
                Text("Lern-Stand wird geladen …")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }

        case .error(let msg):
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(MykColor.critical.color)
                Text(msg)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.critical.color)
                    .lineLimit(2)
            }

        case .content(let stand):
            if stand.istLeer {
                Text("Noch nichts gelernt. Hake bei einer Anpassung den Lern-Schalter an — ab drei ähnlichen Korrekturen entsteht ein Kandidat.")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: MykSpace.s4) {
                    if !stand.aktiveFaktoren.isEmpty {
                        VStack(alignment: .leading, spacing: MykSpace.s2) {
                            ForEach(stand.aktiveFaktoren) { faktor in
                                AktiverFaktorRow(faktor: faktor)
                            }
                        }
                    }
                    if !stand.kandidaten.isEmpty {
                        VStack(alignment: .leading, spacing: MykSpace.s2) {
                            ForEach(stand.kandidaten) { kandidat in
                                KandidatRow(
                                    kandidat: kandidat,
                                    promoting: promotingID == kandidat.id,
                                    promoteDisabled: promotingID != nil,
                                    onPromote: { await promote(kandidat) }
                                )
                            }
                        }
                    }
                    if let bestaetigung = promoteBestaetigung {
                        HStack(spacing: MykSpace.s2) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(MykColor.positive.color)
                            Text(bestaetigung)
                                .font(.mykMono(9.5))
                                .foregroundStyle(MykColor.positive.color)
                                .lineLimit(2)
                        }
                    }
                    if stand.outliers > 0 {
                        Text("\(stand.outliers) Ausreißer übersprungen (>25 %)")
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.faint.color)
                    }
                }
            }
        }
    }

    // MARK: Freitext-Eingabe

    private var freitextField: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            TextField("Projektbeschreibung eingeben …", text: $freitext, axis: .vertical)
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(MykSpace.s4)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .fill(MykColor.card.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: MykRadius.sm)
                                .stroke(MykColor.line.color, lineWidth: 1)
                        )
                )

            Button {
                Task { await schaetzen() }
            } label: {
                HStack(spacing: MykSpace.s3) {
                    if case .loading = state {
                        ProgressView().controlSize(.small)
                            .tint(MykColor.tasks.color)
                    }
                    Text(freitext.trimmingCharacters(in: .whitespaces).isEmpty
                         ? "Schätzen"
                         : "Neu schätzen")
                        .font(.mykSmall).fontWeight(.semibold)
                        .foregroundStyle(MykColor.paper.color)
                }
                .padding(.horizontal, MykSpace.s5)
                .padding(.vertical, MykSpace.s3)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .fill(freitext.trimmingCharacters(in: .whitespaces).isEmpty
                              ? MykColor.faint.color
                              : MykColor.tasks.color)
                )
            }
            .buttonStyle(.plain)
            .disabled(freitext.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: Ergebnis-Bereich

    @ViewBuilder
    private var resultArea: some View {
        switch state {
        case .empty:
            Text("Beschreibe das Projekt, um eine Schätzung zu erhalten.")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)

        case .loading:
            HStack(spacing: MykSpace.s3) {
                ProgressView().controlSize(.small).tint(MykColor.tasks.color)
                Text("Schätzung läuft …")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }

        case .content(let schaetzung):
            KalkulationsResultView(schaetzung: schaetzung)

        case .error(let msg):
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(MykColor.critical.color)
                Text(msg)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.critical.color)
            }
        }
    }

    // MARK: Konfidenz-Badge

    @ViewBuilder
    private var confidenceBadge: some View {
        if case .content(let s) = state {
            let pct = Int(s.confidence * 100)
            let color: Color = s.confidence >= 0.7
                ? MykColor.positive.color
                : (s.confidence >= 0.4 ? MykColor.tasks.color : MykColor.critical.color)
            Text("\(pct) %")
                .font(.mykMono(10))
                .foregroundStyle(color)
                .padding(.horizontal, MykSpace.s4)
                .padding(.vertical, MykSpace.s2)
                .background(Capsule().fill(color.opacity(0.12)))
        }
    }

    // MARK: Quellenzeile

    private var sourceRow: some View {
        HStack(spacing: 8) {
            Circle().fill(MykColor.tasks.color).frame(width: 5, height: 5)
            Text("KALKULATION  ·  BASELINE-ANKER")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.vertical, MykSpace.s4)
        .overlay(alignment: .top) {
            Divider().overlay(MykColor.line.color)
        }
    }

    // MARK: Engine-Aufruf

    private func schaetzen() async {
        let text = freitext.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { state = .empty; return }
        state = .loading
        // Neue Schätzung → Anpassungs-Card frisch
        faktor = 1.0
        grund = ""
        lernen = false
        adjustmentState = .idle
        do {
            let ergebnis = try await engine.schaetze(projektID: projektID, freitext: text)
            state = .content(ergebnis)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: Anpassung bestätigen (Bestätigung → recordAdjustment → Audit)

    private func anpassen(schaetzung: KostenSchaetzung) async {
        let begruendung = grund.trimmingCharacters(in: .whitespaces)
        guard !begruendung.isEmpty else { return }
        adjustmentState = .saving
        do {
            try await engine.recordAdjustment(
                schaetzungsID: schaetzung.schaetzungsID,
                faktor: faktor,
                grund: begruendung,
                lernen: lernen
            )
            adjustmentState = .saved
            // Mit gesetztem Haken kann ein neuer Kandidat entstanden sein → Sektion
            // neu laden und aufklappen, damit der Lern-Fortschritt sofort sichtbar ist.
            if lernen {
                await ladeLernStand()
                lernExpanded = true
            }
            // Card nach 2,5 s in Ruhestand zurückversetzen (inkl. Felder zurücksetzen),
            // damit der Nutzer sofort eine weitere Anpassung erfassen kann.
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            adjustmentState = .idle
            faktor = 1.0
            grund = ""
            lernen = false
        } catch {
            adjustmentState = .failed(error.localizedDescription)
        }
    }

    // MARK: Lern-Loop: laden + promoten

    private func ladeLernStand() async {
        do {
            let stand = try await engine.lernUebersicht()
            lernState = .content(stand)
        } catch {
            lernState = .error(error.localizedDescription)
        }
    }

    private func promote(_ kandidat: KalkulationsKandidat) async {
        guard promotingID == nil else { return }
        promotingID = kandidat.id
        promoteBestaetigung = nil
        do {
            try await engine.promote(candidateID: kandidat.id)
            promoteBestaetigung = "Kalibrierung übernommen: \(kandidat.grundLabel) · \(kandidat.zielLabel)"
            await ladeLernStand()
            // Bestätigungszeile nach 3 s ausblenden — der Kandidat ist nun als
            // aktiver Faktor in der Liste sichtbar, die Meldung nicht mehr nötig.
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            promoteBestaetigung = nil
        } catch {
            lernState = .error(error.localizedDescription)
        }
        promotingID = nil
    }
}

// MARK: - AdjustmentState

private enum AdjustmentState: Equatable {
    case idle
    case saving
    case saved
    case failed(String)
}

// MARK: - KalkulationsRenderState

private enum KalkulationsRenderState {
    case empty
    case loading
    case content(KostenSchaetzung)
    case error(String)
}

// MARK: - LernState

private enum LernState {
    case loading
    case content(KalkulationsLernStand)
    case error(String)
}

// MARK: - AktiverFaktorRow

private struct AktiverFaktorRow: View {
    let faktor: KalkulationsFaktor

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            Circle().fill(MykColor.positive.color).frame(width: 5, height: 5)
            Text(faktor.grundLabel)
                .font(.mykSmall).fontWeight(.medium)
                .foregroundStyle(MykColor.inkSoft.color)
            Text("·")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
            Text(faktor.zielLabel)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
                .lineLimit(1)
            Spacer()
            Text(prozentLabel)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.positive.color)
            Text("n=\(faktor.sampleCount)")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    private var prozentLabel: String {
        let p = Int(faktor.prozent.rounded())
        return p >= 0 ? "+\(p) %" : "\(p) %"
    }
}

// MARK: - KandidatRow

private struct KandidatRow: View {
    let kandidat: KalkulationsKandidat
    let promoting: Bool
    let promoteDisabled: Bool
    let onPromote: () async -> Void

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            Circle()
                .strokeBorder(MykColor.tasks.color, lineWidth: 1.5)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(kandidat.grundLabel)
                        .font(.mykSmall).fontWeight(.medium)
                        .foregroundStyle(MykColor.inkSoft.color)
                    Text("·")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.faint.color)
                    Text(kandidat.zielLabel)
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                        .lineLimit(1)
                }
                Text("\(kandidat.statusLabel) · \(prozentLabel) · n=\(kandidat.sampleCount)")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            Button {
                Task { await onPromote() }
            } label: {
                HStack(spacing: MykSpace.s2) {
                    if promoting {
                        ProgressView().controlSize(.small).tint(MykColor.tasks.color)
                    }
                    Text("Übernehmen")
                        .font(.mykSmall).fontWeight(.semibold)
                        .foregroundStyle(MykColor.paper.color)
                }
                .padding(.horizontal, MykSpace.s4)
                .padding(.vertical, MykSpace.s2)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .fill(promoteDisabled ? MykColor.faint.color : MykColor.tasks.color)
                )
            }
            .buttonStyle(.plain)
            .disabled(promoteDisabled)
        }
    }

    private var prozentLabel: String {
        let p = Int(kandidat.prozent.rounded())
        return p >= 0 ? "+\(p) %" : "\(p) %"
    }
}

// MARK: - KalkulationsResultView

private struct KalkulationsResultView: View {
    let schaetzung: KostenSchaetzung

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            preisRange
            if !schaetzung.topEvidences.isEmpty {
                evidences
            }
            metaRow
        }
    }

    // Min / Mitte / Max

    private var preisRange: some View {
        HStack(spacing: 0) {
            PreisSaeule(label: "Min", betrag: schaetzung.minNetto, accent: MykColor.people.color)
            Divider().frame(height: 48).overlay(MykColor.line.color).padding(.horizontal, MykSpace.s4)
            PreisSaeule(label: "Mitte", betrag: schaetzung.mitteNetto, accent: MykColor.tasks.color, prominent: true)
            Divider().frame(height: 48).overlay(MykColor.line.color).padding(.horizontal, MykSpace.s4)
            PreisSaeule(label: "Max", betrag: schaetzung.maxNetto, accent: MykColor.drive.color)
            Spacer()
        }
    }

    // Top-Evidenzen

    private var evidences: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("Quellen")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            ForEach(Array(schaetzung.topEvidences.prefix(3).enumerated()), id: \.offset) { _, ev in
                EvidenceRow(evidence: ev)
            }
        }
    }

    // Kostenboden & Evidenz-Anzahl

    private var metaRow: some View {
        HStack(spacing: MykSpace.s5) {
            Label {
                Text(formatPreis(schaetzung.kostenboden))
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.inkSoft.color)
            } icon: {
                Text("Kostenboden")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            Text("\(schaetzung.evidenceCount) Evidenzen")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    // MARK: Hilfsmethoden

    private func formatPreis(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "–"
    }
}

// MARK: - PreisSaeule

private struct PreisSaeule: View {
    let label: String
    let betrag: Double
    var accent: Color = MykColor.tasks.color
    var prominent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            Text(formattedBetrag)
                .font(prominent ? .mykTitle : .mykHeadline)
                .foregroundStyle(prominent ? accent : MykColor.inkSoft.color)
        }
    }

    private var formattedBetrag: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: betrag)) ?? "–"
    }
}

// MARK: - KalkulationsActionCard
// Vorschlag einer Anpassung. Schreibt NIE automatisch — erst der Bestätigungs-Button
// löst recordAdjustment (LearningStore + Audit) aus. Gleiche Semantik wie die
// Action-Cards im AssistantWidget.
private struct KalkulationsActionCard: View {
    @Binding var faktor: Double
    @Binding var grund: String
    @Binding var lernen: Bool
    let state: AdjustmentState
    let onConfirm: () async -> Void

    private var prozent: Int { Int(((faktor - 1) * 100).rounded()) }

    private var prozentLabel: String {
        if prozent == 0 { return "unverändert" }
        return prozent > 0 ? "+\(prozent) % höher" : "\(prozent) % günstiger"
    }

    private var grundLeer: Bool {
        grund.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var saving: Bool {
        if case .saving = state { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text("Anpassung vorschlagen")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)

            // Faktor-Schieberegler
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                HStack {
                    Text("Faktor")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.inkSoft.color)
                    Spacer()
                    Text(prozentLabel)
                        .font(.mykMono(10))
                        .foregroundStyle(prozent == 0 ? MykColor.muted.color
                                         : (prozent > 0 ? MykColor.drive.color : MykColor.positive.color))
                }
                Slider(value: $faktor, in: 0.5...1.5, step: 0.05)
                    .tint(MykColor.tasks.color)
                    .disabled(saving)
            }

            // Begründung
            TextField("Grund (z. B. Aufmaß war kleiner)", text: $grund, axis: .vertical)
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .padding(MykSpace.s4)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .fill(MykColor.card.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: MykRadius.sm)
                                .stroke(MykColor.line.color, lineWidth: 1)
                        )
                )
                .disabled(saving)

            // „Lernen"-Schalter — ohne Haken bleibt es eine reine Einzelkorrektur.
            Toggle(isOn: $lernen) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Für künftige Schätzungen lernen")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.inkSoft.color)
                    Text("Ab drei ähnlichen Anpassungen entsteht ein Kalibrierungs-Kandidat.")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                }
            }
            .toggleStyle(.switch)
            .tint(MykColor.tasks.color)
            .disabled(saving)

            // Bestätigung + Status
            HStack(spacing: MykSpace.s4) {
                Button {
                    Task { await onConfirm() }
                } label: {
                    HStack(spacing: MykSpace.s3) {
                        if saving {
                            ProgressView().controlSize(.small).tint(MykColor.tasks.color)
                        }
                        Text("Anpassung buchen")
                            .font(.mykSmall).fontWeight(.semibold)
                            .foregroundStyle(MykColor.paper.color)
                    }
                    .padding(.horizontal, MykSpace.s5)
                    .padding(.vertical, MykSpace.s3)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill((grundLeer || saving) ? MykColor.faint.color : MykColor.tasks.color)
                    )
                }
                .buttonStyle(.plain)
                .disabled(grundLeer || saving)

                statusLabel
                Spacer()
            }
        }
        .padding(MykSpace.s5)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.sm)
                .fill(MykColor.card.color.opacity(0.5))
        )
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch state {
        case .idle, .saving:
            EmptyView()
        case .saved:
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MykColor.positive.color)
                Text("Im Audit protokolliert")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.positive.color)
            }
        case .failed(let msg):
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(MykColor.critical.color)
                Text(msg)
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.critical.color)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - EvidenceRow

private struct EvidenceRow: View {
    let evidence: PriceEvidence

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            RoundedRectangle(cornerRadius: 3)
                .fill(MykColor.tasks.color.opacity(0.2))
                .frame(width: 3, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(evidence.lieferant)
                        .font(.mykSmall).fontWeight(.medium)
                        .foregroundStyle(MykColor.inkSoft.color)
                    Text("·")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.faint.color)
                    Text(evidence.dokument)
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                        .lineLimit(1)
                }
                Text(evidence.originalZitat)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                    .lineLimit(1)
            }
            Spacer()
            Text(formatPreis(evidence.nettoPreis))
                .font(.mykMono(10))
                .foregroundStyle(MykColor.tasks.color)
        }
    }

    private func formatPreis(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "–"
    }
}
