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
    // Selbst-konfigurierbar wie Widgets: welche Kataloge in DIESER Ansicht aktiv sind
    // (leer = alle). Reihenfolge weiterhin per Drag (kataloge.taborder).
    @AppStorage("kataloge.aktiveTabs") private var aktiveTabsRaw: String = ""
    @State private var order: [KatalogTab] = KatalogTab.defaultOrder
    @State private var selected: KatalogTab = .artikel
    @State private var showTabSelector = false

    private var aktiveTabs: Set<KatalogTab> {
        let parsed = aktiveTabsRaw.split(separator: ",").compactMap { KatalogTab(rawValue: String($0)) }
        return parsed.isEmpty ? Set(KatalogTab.allCases) : Set(parsed)
    }
    private var sichtbareTabs: [KatalogTab] {
        let sichtbar = order.filter { aktiveTabs.contains($0) }
        return sichtbar.isEmpty ? order : sichtbar
    }
    private func setzeTabAktiv(_ tab: KatalogTab, _ aktiv: Bool) {
        var set = aktiveTabs
        if aktiv { set.insert(tab) } else if set.count > 1 { set.remove(tab) }  // nie alle deaktivieren
        aktiveTabsRaw = order.filter { set.contains($0) }.map(\.rawValue).joined(separator: ",")
        if !set.contains(selected) { selected = order.first { set.contains($0) } ?? .artikel }
    }

    // Webshop: listenübergreifender Warenkorb (lokal, in-session)
    @State private var warenkorb = WarenkorbState()
    // Shared data stores — einmal initialisiert, an Shop-Tabs weitergegeben
    @State private var artikelStore = ArtikelKatalogStore()
    @State private var lagerStore = LagerlisteStore()
    @State private var warenkorbListeStore = WarenkorbListeStore()
    // Intake: Fragebogen-Sheet. Der Entwurf selbst lebt in AppState (Erinnerungsfunktion,
    // siehe dort) — hier nur noch ein lokaler Binding-Helfer für `.sheet(isPresented:)`.
    private var zeigeFragebogenBinding: Binding<Bool> {
        Binding(get: { appState.zeigeFragebogen }, set: { appState.zeigeFragebogen = $0 })
    }

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
            .sheet(isPresented: zeigeFragebogenBinding) {
                // Erinnerungsfunktion (Johannes, 2026-07-01): `appState.fragebogenEntwurf` wird
                // HIER nicht bei jedem Schließen zurückgesetzt — sonst gingen alle Eingaben bei
                // jedem temporären Schließen (z. B. während der 422-Fehlersuche) verloren, UND
                // (Härtung) er lebt bewusst in AppState statt in KatalogeViews eigenem @State,
                // damit ein Sidebar-Modulwechsel ihn nicht mitzerstört. FragebogenView selbst
                // leert das Modell nur noch gezielt: nach einem bestätigten "Verwerfen" oder
                // automatisch nach einer erfolgreichen Anlage (siehe dort).
                FragebogenView(modell: appState.fragebogenEntwurf) {
                    appState.zeigeFragebogen = false
                }
                .environment(appState)
                // Härtung (2026-07-01, Audit): ohne dies dismisst macOS das Sheet per Escape-
                // Taste direkt über das Binding — das umgeht ALLE `.disabled(schreibPhase ==
                // .speichert)`-Sperren in FragebogenView (Verwerfen/X/Abbrechen/Stufen-Picker),
                // weil dabei kein einziger FragebogenView-Button-Handler aufgerufen wird.
                .interactiveDismissDisabled(appState.fragebogenSchreibtGerade)
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
            // UI-Polish (2026-07-02, Johannes): beschreibender Untertitel entfernt —
            // er wiederholte nur die Tab-Namen, die direkt darunter als echte Tabs stehen.
            Text("Kataloge")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.ink.color)
            Spacer()

            // Intake: + Neues Projekt (Fragebogen)
            Button {
                appState.zeigeFragebogen = true
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
            .accessibilityLabel("Neues Projekt über Fragebogen anlegen")

            // Kataloge-Selektor (welche Tabs aktiv sind — wie der Widget-Selektor)
            Button { showTabSelector.toggle() } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.mykBody)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                    .background(MykColor.card.color)
                    .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Kataloge ein-/ausblenden")
            .accessibilityLabel("Kataloge konfigurieren")
            .popover(isPresented: $showTabSelector, arrowEdge: .bottom) { katalogSelektor }

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
            .accessibilityLabel(warenkorb.istLeer ? "Warenkorb (leer)" : "Warenkorb (\(warenkorb.anzahl) Pos.)")
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s9)
        .padding(.bottom, MykSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Kataloge-Selektor: pro Katalog ein/aus (nie alle aus). Reihenfolge per Drag im Strip.
    private var katalogSelektor: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "square.grid.2x2").font(.mykCaption).foregroundStyle(MykColor.brand.color)
                Text("Kataloge dieser Ansicht").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            }
            Text("Ein-/ausblenden. Reihenfolge per Drag an den Tabs.")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            Divider().overlay(MykColor.line.color)
            ForEach(order) { tab in
                HStack(spacing: MykSpace.s3) {
                    Image(systemName: tab.icon).font(.mykCaption).foregroundStyle(tab.accent.color).frame(width: 20)
                    Text(tab.title).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { aktiveTabs.contains(tab) },
                        set: { setzeTabAktiv(tab, $0) }
                    ))
                    .labelsHidden().toggleStyle(.switch).tint(tab.accent.color)
                    .accessibilityLabel(tab.title)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(MykSpace.s5)
        .frame(width: 300)
        .background(MykColor.card.color)
    }

    private var tabStrip: some View {
        HStack(spacing: MykSpace.s2) {
            ForEach(sichtbareTabs) { tab in
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
        // Auswahl muss ein SICHTBARER (aktiver) Tab sein.
        if !sichtbareTabs.contains(selected) { selected = sichtbareTabs.first ?? .artikel }
    }
}

// MARK: - Geräte-Tab entfernt (Phase 4, 2026-06-30)
// DeviceCatalog/CSV bleibt für KalkulationsEngine.geraetepreis aktiv.
// Nur der Kataloge-Tab wurde entfernt — Artikel/Shop (Live-Airtable) ersetzt ihn.
