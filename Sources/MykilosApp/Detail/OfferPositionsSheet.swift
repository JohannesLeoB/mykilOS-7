import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets
import MykilosKalkulationsCore

// MARK: - OfferPositionsSheet (PDF-Positions v1 · UI Teil 1: read-only Kandidaten)
//
// „Positionen herauslösen" an einem Angebots-PDF → dieses Sheet lädt die Datei
// read-only (Drive `downloadContent`), jagt sie durch `OfferPositionPDFReader`
// (Pass 1 Blocking + Pass 2 Feld-Extraktion) und zeigt die Kandidaten als Karten
// mit Selbstbeweis-Ampel (Menge × Einzel ≈ Gesamt).
//
// SCOPE-GRENZE (bewusst, 2026-07-04): NUR Anzeige. Die Übernahme in den WorkBasket
// (Wirbelsäule) ist der nächste, separate Schritt — braucht das Pick-Mapping +
// Johannes' Semantik-Freigabe. Nichts wird hier geschrieben.
struct OfferPositionsSheet: View {
    let file: GoogleDriveFile
    /// Optionale Übernahme in den Warenkorb (PDF-Positions Teil 2). Fehlt der
    /// Callback (z. B. wo kein Warenkorb im Kontext ist), bleibt das Sheet read-only.
    /// Bekommt Position + stabilen Index → der Aufrufer baut EK/VK aus der Richtung.
    var onTake: ((OfferPositionPDFReader.PagedPosition, Int) -> Void)? = nil
    var onClose: () -> Void

    @State private var loader = OfferPositionsLoader()
    @State private var taken: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)
            content
            Divider().overlay(MykColor.line.color)
            footer
        }
        .frame(minWidth: 560, minHeight: 620)
        .background(MykColor.paper.color)
        .task(id: file.id) { await loader.load(file: file) }
    }

    // MARK: Kopf

    private var header: some View {
        HStack(spacing: MykSpace.s4) {
            SourceChip(kind: .cash)
            VStack(alignment: .leading, spacing: 2) {
                Text("Positionen herauslösen").mykWidgetTitle()
                Text(file.name)
                    .font(.mykMono(10)).foregroundStyle(MykColor.muted.color).lineLimit(1)
            }
            Spacer()
            Button { onClose() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.mykHeadline).foregroundStyle(MykColor.faint.color)
            }
            .buttonStyle(.plain).accessibilityLabel("Schließen")
        }
        .padding(MykSpace.s6)
    }

    // MARK: Inhalt / Zustände

    @ViewBuilder
    private var content: some View {
        switch loader.state {
        case .loading:
            hint(icon: nil, text: "Lese \(file.name) …", spinner: true)
        case .empty:
            hint(icon: "text.magnifyingglass", text: "Keine Positionen mit verwertbarem Preis gefunden.")
        case .error(let msg):
            hint(icon: "exclamationmark.triangle", text: "Konnte die Datei nicht auslesen:\n\(msg)", critical: true)
        case .content(let positions):
            let items = sortiert(positions)
            ScrollView {
                VStack(alignment: .leading, spacing: MykSpace.s4) {
                    ampelLegende(items)
                    ForEach(Array(items.enumerated()), id: \.offset) { index, paged in
                        PositionCard(
                            paged: paged,
                            canTake: onTake != nil,
                            taken: taken.contains(index),
                            onTake: {
                                onTake?(paged, index)
                                taken.insert(index)
                            })
                    }
                }
                .padding(MykSpace.s6)
            }
        }
    }

    // Vertrauenswürdige (grüne, selbstbewiesene) Positionen zuerst, dann nach Seite —
    // deterministisch (Original-Index als letzter Tiebreak, damit `taken`-Index stabil bleibt).
    private func sortiert(_ positions: [OfferPositionPDFReader.PagedPosition]) -> [OfferPositionPDFReader.PagedPosition] {
        func rang(_ c: OfferPositionExtractor.Confidence) -> Int {
            switch c { case .green: 0; case .amber: 1; case .red: 2 }
        }
        return positions.enumerated().sorted { a, b in
            let ra = rang(a.element.position.confidence), rb = rang(b.element.position.confidence)
            if ra != rb { return ra < rb }
            if a.element.pageNumber != b.element.pageNumber { return a.element.pageNumber < b.element.pageNumber }
            return a.offset < b.offset
        }.map(\.element)
    }

    private func ampelLegende(_ positions: [OfferPositionPDFReader.PagedPosition]) -> some View {
        let green = positions.filter { $0.position.confidence == .green }.count
        let amber = positions.filter { $0.position.confidence == .amber }.count
        return HStack(spacing: MykSpace.s5) {
            legendeItem(MykColor.positive.color, "\(green) selbstbewiesen")
            if amber > 0 { legendeItem(MykColor.tasks.color, "\(amber) prüfen") }
            Spacer()
        }
        .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
    }

    private func legendeItem(_ color: Color, _ text: String) -> some View {
        HStack(spacing: MykSpace.s2) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
        }
    }

    private func hint(icon: String?, text: String, spinner: Bool = false, critical: Bool = false) -> some View {
        VStack(spacing: MykSpace.s4) {
            if spinner { ProgressView() }
            if let icon {
                Image(systemName: icon).font(.mykHero)
                    .foregroundStyle(critical ? MykColor.critical.color : MykColor.faint.color)
            }
            Text(text)
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MykSpace.s7)
    }

    // MARK: Fuß

    private var footer: some View {
        HStack(spacing: MykSpace.s3) {
            Circle().fill(MykColor.cash.color).frame(width: 5, height: 5)
            Text(footerText)
                .font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6).padding(.vertical, MykSpace.s4)
    }

    private var footerText: String {
        switch loader.state {
        case .content(let p):
            let base = "PDF-POSITIONS v1 · \(p.count) KANDIDATEN"
            if onTake == nil { return base + " · read-only" }
            return taken.isEmpty ? base : base + " · \(taken.count) ÜBERNOMMEN"
        default:
            return "PDF-POSITIONS v1"
        }
    }
}

// MARK: - PositionCard
private struct PositionCard: View {
    let paged: OfferPositionPDFReader.PagedPosition
    var canTake: Bool = false
    var taken: Bool = false
    var onTake: () -> Void = {}
    @State private var showRaw = false

    private var p: OfferPositionExtractor.ExtractedPosition { paged.position }

    private var ampelColor: Color {
        switch p.confidence {
        case .green: MykColor.positive.color
        case .amber: MykColor.tasks.color
        case .red:   MykColor.critical.color
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(alignment: .top, spacing: MykSpace.s3) {
                Circle().fill(ampelColor).frame(width: 8, height: 8).padding(.top, 5)
                Text(p.title.isEmpty ? "(ohne Titel)" : p.title)
                    .font(.mykBody).foregroundStyle(MykColor.ink.color).lineLimit(2)
                Spacer()
                Text("S. \(paged.pageNumber)")
                    .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                    .padding(.horizontal, MykSpace.s2).padding(.vertical, 2)
                    .background(Capsule().fill(MykColor.line.color.opacity(0.3)))
            }
            HStack(spacing: MykSpace.s3) {
                arithmetikZeile
                Spacer()
                if p.isAlternative { alternativBadge }
                kategorieChip
            }
            if let list = p.listPrice {
                Text("Listenpreis \(euro(list)) · Netto nach Rabatt")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            HStack(spacing: MykSpace.s4) {
                Button { withAnimation(.easeInOut(duration: 0.12)) { showRaw.toggle() } } label: {
                    Text(showRaw ? "Originaltext ausblenden" : "Originaltext")
                        .font(.mykMono(9)).foregroundStyle(MykColor.cash.color)
                }
                .buttonStyle(.plain)
                Spacer()
                if canTake { uebernahmeButton }
            }
            if showRaw {
                Text(p.originalText)
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                    .textSelection(.enabled)
                    .padding(MykSpace.s3)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.paper2.color))
            }
        }
        .padding(MykSpace.s5)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
    }

    // Warnhinweis für Alternativ-/Bedarfspositionen — nicht blind aufsummieren.
    private var alternativBadge: some View {
        Text("Alternative")
            .font(.mykMono(8.5)).foregroundStyle(MykColor.paper.color)
            .padding(.horizontal, MykSpace.s2).padding(.vertical, 2)
            .background(Capsule().fill(MykColor.tasks.color))
            .help("Alternativ-/Bedarfsposition — gehört evtl. nicht in die Summe.")
    }

    // Bauteil-Kategorie als dezenter Chip (aus dem Text klassifiziert). `.other`
    // wird nicht gezeigt — kein Rauschen für Unklassifiziertes.
    @ViewBuilder
    private var kategorieChip: some View {
        if p.componentType != .other {
            Text(p.componentType.displayName)
                .font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s3).padding(.vertical, 2)
                .background(Capsule().fill(MykColor.line.color.opacity(0.3)))
        }
    }

    // "3 Stk × 12,00 € = 36,00 €" wenn selbstbewiesen, sonst der reine Netto-Preis.
    @ViewBuilder
    private var arithmetikZeile: some View {
        if let net = p.netPrice {
            if p.confidence == .green, let menge = p.quantity, let total = p.lineTotal, menge > 1 {
                HStack(spacing: MykSpace.s2) {
                    Text(mengeText(menge)).foregroundStyle(MykColor.ink.color)
                    Text("×").foregroundStyle(MykColor.faint.color)
                    Text(euro(net)).foregroundStyle(MykColor.ink.color)
                    Text("=").foregroundStyle(MykColor.faint.color)
                    Text(euro(total)).foregroundStyle(MykColor.positive.color)
                }
                .font(.mykMono(11))
            } else {
                Text(euro(net))
                    .font(.mykMono(12)).foregroundStyle(MykColor.ink.color)
            }
        }
    }

    // Ein Klick = Übernahme dieser einen Position (etabliertes Bestätigungs-Muster).
    // Nur wenn ein Preis da ist (rote Karten ohne Preis sind nicht übernehmbar).
    @ViewBuilder
    private var uebernahmeButton: some View {
        if taken {
            Label("Im Warenkorb", systemImage: "checkmark.circle.fill")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.positive.color)
        } else if p.netPrice != nil {
            Button(action: onTake) {
                Label("In Warenkorb", systemImage: "cart.badge.plus")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                    .background(Capsule().fill(MykColor.cash.color))
            }
            .buttonStyle(.plain)
            .help("Diese Position in den Warenkorb übernehmen")
        }
    }

    private func mengeText(_ m: Double) -> String {
        let n = m.formatted(.number.precision(.fractionLength(0...2)))
        return "\(n) \(p.unit ?? "Stk")"
    }

    private func euro(_ d: Decimal) -> String {
        (d as NSDecimalNumber).doubleValue
            .formatted(.currency(code: "EUR").locale(Locale(identifier: "de_DE")))
    }
}

// MARK: - OfferPositionsLoader
@MainActor
@Observable
private final class OfferPositionsLoader {
    enum State {
        case loading
        case content([OfferPositionPDFReader.PagedPosition])
        case empty
        case error(String)
    }
    private(set) var state: State = .loading

    private let client: GoogleDriveFetching
    private var gen = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(file: GoogleDriveFile) async {
        gen &+= 1
        let mine = gen
        state = .loading
        do {
            let data = try await client.downloadContent(fileID: file.id)
            // Extraktion ist rein CPU — vom MainActor runter.
            let positions = await Task.detached(priority: .userInitiated) {
                OfferPositionPDFReader.positions(fromPDFData: data)
            }.value
            guard mine == gen else { return }
            state = positions.isEmpty ? .empty : .content(positions)
        } catch {
            guard mine == gen else { return }
            state = .error(String(describing: error))
        }
    }
}
