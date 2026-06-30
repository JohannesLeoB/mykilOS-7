import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - KatalogTab
// Die Unter-Tabs der Kataloge-Seite. Reihenfolge ist umsortierbar (Drag) und wird
// in @AppStorage gemerkt.
// Phase 3 (Webshop): „Artikel/Shop", „Lager", „Angebote".
// Phase 4 (2026-06-30): „Warenkörbe" hinzugekommen; „Geräte"-Tab entfernt
//   (DeviceCatalog/CSV bleibt für KalkulationsEngine.geraetepreis).
enum KatalogTab: String, CaseIterable, Identifiable {
    case artikel, lager, warenkörbe, angebote, kontakte, notizen, aufgaben
    var id: String { rawValue }

    var title: String {
        switch self {
        case .artikel:    "Artikel / Shop"
        case .lager:      "Lager"
        case .warenkörbe: "Warenkörbe"
        case .angebote:   "Angebote"
        case .kontakte:   "Kontakte"
        case .notizen:    "Notizen"
        case .aufgaben:   "Aufgaben"
        }
    }
    var icon: String {
        switch self {
        case .artikel:    "cart"
        case .lager:      "archivebox"
        case .warenkörbe: "cart.fill"
        case .angebote:   "doc.text"
        case .kontakte:   "person.2"
        case .notizen:    "note.text"
        case .aufgaben:   "checklist"
        }
    }
    var accent: MykColor {
        switch self {
        case .artikel:    .tasks
        case .lager:      .drive
        case .warenkörbe: .cash
        case .angebote:   .cash
        case .kontakte:   .people
        case .notizen:    .personal
        case .aufgaben:   .tasks
        }
    }

    static var defaultOrder: [KatalogTab] {
        [.artikel, .lager, .warenkörbe, .angebote, .kontakte, .notizen, .aufgaben]
    }
}

// MARK: - KatalogeView
// Hülle mit umsortierbarer Tab-Leiste; der aktive Tab füllt den Rest.
// Phase 3: Warenkorb-State ist @State hier, damit er alle Tabs überlebt.
// Phase 4: WarenkorbListeStore hinzugekommen; Geräte-Tab entfernt.
// Shared Stores: ArtikelKatalogStore + LagerlisteStore + WarenkorbListeStore
//   werden einmal erstellt und an die jeweiligen Tabs weitergegeben.
@MainActor
struct KatalogeView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("kataloge.taborder") private var orderRaw: String = ""
    @State private var order: [KatalogTab] = KatalogTab.defaultOrder
    @State private var selected: KatalogTab = .artikel

    // Webshop: listenübergreifender Warenkorb (lokal, in-session)
    @State private var warenkorb = WarenkorbState()
    // Shared data stores — einmal initialisiert, an Shop-Tabs weitergegeben
    @State private var artikelStore = ArtikelKatalogStore()
    @State private var lagerStore = LagerlisteStore()
    @State private var warenkorbListeStore = WarenkorbListeStore()
    // Intake: Fragebogen-Sheet
    @State private var zeigeFragebogen: Bool = false
    @State private var frageBogenModell = FragebogenModel()

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
            .sheet(isPresented: $zeigeFragebogen, onDismiss: {
                // Fragebogen-Modell nach Schließen zurücksetzen
                frageBogenModell = FragebogenModel()
            }) {
                FragebogenView(modell: frageBogenModell) {
                    zeigeFragebogen = false
                }
                .environment(appState)
            }

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
                Text("Artikel, Lager, Warenkörbe, Angebote, Kontakte, Notizen \u{00B7} Tabs ziehen zum Umsortieren")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()

            // Intake: + Neues Projekt (Fragebogen)
            Button {
                zeigeFragebogen = true
            } label: {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "plus")
                        .font(.mykCaption)
                    Text("Neues Projekt")
                        .font(.mykSmall)
                }
                .foregroundStyle(MykColor.paper.color)
                .padding(.horizontal, MykSpace.s4)
                .padding(.vertical, MykSpace.s2)
                .background(MykColor.brand.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            }
            .buttonStyle(.plain)
            .help("Neues Projekt über Fragebogen anlegen")

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
        case .warenkörbe:
            WarenkorbListeTab(warenkorb: warenkorb, store: warenkorbListeStore)
        case .angebote:
            GlobalOffersView()
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

// MARK: - Geräte-Tab entfernt (Phase 4, 2026-06-30)
// DeviceCatalog/CSV bleibt für KalkulationsEngine.geraetepreis aktiv.
// Nur der Kataloge-Tab wurde entfernt — Artikel/Shop (Live-Airtable) ersetzt ihn.
