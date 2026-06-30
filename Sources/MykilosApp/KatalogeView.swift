import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - KatalogTab
// Die Unter-Tabs der Kataloge-Seite. Reihenfolge ist umsortierbar (Drag) und wird
// in @AppStorage gemerkt.
// Phase 3 (Webshop): neue Tabs „Artikel/Shop", „Lager", „Angebote" hinzugekommen.
// „Angebote" ersetzt AppModule.offers in der Sidebar (analog zur Mail-Lösung).
enum KatalogTab: String, CaseIterable, Identifiable {
    case artikel, lager, angebote, geraete, kontakte, notizen, aufgaben
    var id: String { rawValue }

    var title: String {
        switch self {
        case .artikel:  "Artikel / Shop"
        case .lager:    "Lager"
        case .angebote: "Angebote"
        case .geraete:  "Geräte"
        case .kontakte: "Kontakte"
        case .notizen:  "Notizen"
        case .aufgaben: "Aufgaben"
        }
    }
    var icon: String {
        switch self {
        case .artikel:  "cart"
        case .lager:    "archivebox"
        case .angebote: "doc.text"
        case .geraete:  "square.grid.2x2"
        case .kontakte: "person.2"
        case .notizen:  "note.text"
        case .aufgaben: "checklist"
        }
    }
    var accent: MykColor {
        switch self {
        case .artikel:  .tasks
        case .lager:    .drive
        case .angebote: .cash
        case .geraete:  .tasks
        case .kontakte: .people
        case .notizen:  .personal
        case .aufgaben: .tasks
        }
    }

    static var defaultOrder: [KatalogTab] {
        [.artikel, .lager, .angebote, .geraete, .kontakte, .notizen, .aufgaben]
    }
}

// MARK: - KatalogeView
// Hülle mit umsortierbarer Tab-Leiste; der aktive Tab füllt den Rest.
// Phase 3: Warenkorb-State ist @State hier, damit er alle Tabs überlebt.
// Shared Stores: ArtikelKatalogStore + LagerlisteStore werden einmal erstellt und an
// Artikel-Tab + Lager-Tab weitergegeben — nicht doppelt geladen.
@MainActor
struct KatalogeView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("kataloge.taborder") private var orderRaw: String = ""
    @State private var order: [KatalogTab] = KatalogTab.defaultOrder
    @State private var selected: KatalogTab = .artikel

    // Webshop Phase 3: listenübergreifender Warenkorb (lokal, in-session)
    @State private var warenkorb = WarenkorbState()
    // Shared data stores — einmal initialisiert, an beide Shop-Tabs weitergegeben
    @State private var artikelStore = ArtikelKatalogStore()
    @State private var lagerStore = LagerlisteStore()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                header
                tabStrip
                Divider().overlay(MykColor.line.color)
                content
            }
            .background(MykColor.paper.color)
            .onAppear { loadOrder() }

            // Warenkorb-Floating-Panel (rechts oben eingeblendet)
            if warenkorb.showPanel {
                WarenkorbPanel(warenkorb: warenkorb)
                    .padding(.top, MykSpace.s9)
                    .padding(.trailing, MykSpace.s7)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: warenkorb.showPanel)
    }

    // MARK: Header + Tab-Leiste

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text("Kataloge")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
                Text("Artikel, Lager, Angebote, Geräte, Kontakte, Notizen \u{00B7} Tabs ziehen zum Umsortieren")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            // Warenkorb-Badge-Button
            Button {
                warenkorb.showPanel.toggle()
            } label: {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: warenkorb.istLeer ? "cart" : "cart.badge.plus")
                        .font(.mykBody)
                        .foregroundStyle(warenkorb.istLeer ? MykColor.faint.color : MykColor.tasks.color)
                    if !warenkorb.istLeer {
                        Text("\(warenkorb.anzahl)")
                            .font(.mykMono(10))
                            .foregroundStyle(MykColor.tasks.color)
                    }
                }
                .padding(.horizontal, MykSpace.s4)
                .padding(.vertical, MykSpace.s2)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .stroke(warenkorb.istLeer ? MykColor.line.color : MykColor.tasks.color.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help(warenkorb.istLeer ? "Warenkorb (leer)" : "Warenkorb (\(warenkorb.anzahl) Pos.)")
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s9)
        .padding(.bottom, MykSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tabStrip: some View {
        HStack(spacing: MykSpace.s2) {
            ForEach(order) { tab in
                tabPill(tab)
                    .draggable(tab.rawValue) {
                        tabPillLabel(tab, active: false).opacity(0.9)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        handleDrop(items, onto: tab)
                    }
            }
            Spacer()
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.bottom, MykSpace.s3)
    }

    private func tabPill(_ tab: KatalogTab) -> some View {
        Button { selected = tab } label: { tabPillLabel(tab, active: selected == tab) }
            .buttonStyle(.plain)
    }

    private func tabPillLabel(_ tab: KatalogTab, active: Bool) -> some View {
        HStack(spacing: MykSpace.s2) {
            Image(systemName: tab.icon)
                .font(.mykCaption)
            Text(tab.title)
                .font(.mykSmall)
        }
        .foregroundStyle(active ? MykColor.paper.color : MykColor.muted.color)
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, MykSpace.s2)
        .background(active ? tab.accent.color : MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.sm)
                .stroke(active ? Color.clear : MykColor.line.color, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch selected {
        case .artikel:
            ArtikelShopTab(warenkorb: warenkorb, artikelStore: artikelStore, lagerStore: lagerStore)
        case .lager:
            LagerTab(warenkorb: warenkorb, lagerStore: lagerStore)
        case .angebote:
            GlobalOffersView()
        case .geraete:  GeraeteKatalogTab()
        case .kontakte: KontakteKatalogTab()
        case .notizen:  NotizenKatalogTab()
        case .aufgaben: AufgabenKatalogTab()
        }
    }

    // MARK: Reorder-Persistenz

    private func handleDrop(_ items: [String], onto target: KatalogTab) -> Bool {
        guard let raw = items.first, let dragged = KatalogTab(rawValue: raw),
              dragged != target,
              let from = order.firstIndex(of: dragged),
              let toIdx = order.firstIndex(of: target) else { return false }
        withAnimation(.easeInOut(duration: 0.18)) {
            order.move(fromOffsets: IndexSet(integer: from),
                       toOffset: toIdx > from ? toIdx + 1 : toIdx)
        }
        orderRaw = order.map(\.rawValue).joined(separator: ",")
        return true
    }

    private func loadOrder() {
        let parsed = orderRaw.split(separator: ",").compactMap { KatalogTab(rawValue: String($0)) }
        // Fehlende Tabs (z. B. nach Update) hinten anhängen, Duplikate filtern.
        var seen = Set<KatalogTab>()
        var result: [KatalogTab] = []
        for t in parsed where !seen.contains(t) { result.append(t); seen.insert(t) }
        for t in KatalogTab.defaultOrder where !seen.contains(t) { result.append(t); seen.insert(t) }
        order = result
        if let first = order.first { selected = order.contains(selected) ? selected : first }
    }
}

// MARK: - Geräte-Katalog (read-only DeviceCatalog)

@MainActor
private struct GeraeteKatalogTab: View {
    @State private var catalog: DeviceCatalog? = nil
    @State private var query: String = ""
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchBar
            if isLoading {
                loadingState
            } else if catalog == nil {
                emptyState
            } else {
                resultsTable
            }
        }
        .task { await loadCatalog() }
    }

    private var searchBar: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "magnifyingglass")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
            TextField("Hersteller, Kategorie, Artikelnummer …", text: $query)
                .font(.mykBody)
                .textFieldStyle(.plain)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.faint.color)
                }
                .buttonStyle(.plain)
            }
            if let c = catalog {
                Text("\(c.entries.count) Artikel \u{00B7} read-only")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
            }
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        .padding(MykSpace.s9)
    }

    private var resultsTable: some View {
        let results = filteredResults
        return VStack(spacing: 0) {
            tableHeader
            if results.isEmpty {
                Text("Keine Treffer für \"\(query)\"")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(MykSpace.s9)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.offset) { _, entry in
                            KatalogeRow(entry: entry)
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
                Text("\(results.count) Artikel angezeigt")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
                    .padding(.vertical, MykSpace.s3)
                    .padding(.horizontal, MykSpace.s9)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Hersteller").frame(width: 120, alignment: .leading)
            Text("Kategorie").frame(width: 130, alignment: .leading)
            Text("Beschreibung").frame(maxWidth: .infinity, alignment: .leading)
            Text("Art.-Nr.").frame(width: 110, alignment: .leading)
            Text("MYKILOS-VK").frame(width: 90, alignment: .trailing)
        }
        .font(.mykMono(9))
        .foregroundStyle(MykColor.muted.color)
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s2)
        .background(MykColor.paper2.color)
    }

    private var loadingState: some View {
        VStack { Spacer(); ProgressView("Lade Katalog …").font(.mykSmall).foregroundStyle(MykColor.muted.color); Spacer() }
            .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: MykSpace.s4) {
            Image(systemName: "tray.slash")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.faint.color)
            Text("Kein Gerätekatalog gefunden")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.muted.color)
            Text("CSV unter:\n\(DeviceCatalog.defaultURL().path)")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MykSpace.s9)
    }

    private var filteredResults: [DeviceCatalogEntry] {
        guard let catalog else { return [] }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return Array(catalog.entries.prefix(200)) }
        return catalog.search(q, limit: 200)
    }

    private func loadCatalog() async {
        let loaded = await Task.detached(priority: .userInitiated) { DeviceCatalog.loadDefault() }.value
        catalog = loaded
        isLoading = false
    }
}

// MARK: - KatalogeRow (Geräte-Zeile)

private struct KatalogeRow: View {
    let entry: DeviceCatalogEntry
    @State private var isHovered = false

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            Text(entry.manufacturer)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
            Text(entry.category)
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 130, alignment: .leading)
                .lineLimit(1)
            Text(entry.description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
            Text(entry.articleNumber)
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)
            if let price = entry.sellNet {
                Text(Self.priceFormatter.string(from: price as NSDecimalNumber) ?? "–")
                    .foregroundStyle(MykColor.tasks.color)
                    .frame(width: 90, alignment: .trailing)
            } else {
                Text("–")
                    .foregroundStyle(MykColor.faint.color)
                    .frame(width: 90, alignment: .trailing)
            }
        }
        .font(.mykMono(10))
        .foregroundStyle(MykColor.ink.color)
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(isHovered ? MykColor.paper2.color : Color.clear)
        .onHover { isHovered = $0 }
    }
}
