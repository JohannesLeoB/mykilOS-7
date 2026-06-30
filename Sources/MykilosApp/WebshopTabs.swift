import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - ArtikelShopTab
// Kataloge-Tab „Artikel / Shop": lädt den Live-Artikel-Katalog (ArtikelKatalogStore,
// ~13.419 Records), sucht/filtert clientseitig, zeigt Auf-Lager-Badge per AufLagerMatcher.
// „+ Warenkorb"-Button je Artikel → WarenkorbState.addArtikel.
// Lager-Daten kommen aus dem gemeinsamen LagerlisteStore (übergeben aus KatalogeView).
@MainActor
struct ArtikelShopTab: View {

    @Environment(AppState.self) private var appState
    @Bindable var warenkorb: WarenkorbState

    // Shared stores (übergeben aus KatalogeView, damit Lager nur einmal geladen wird)
    @Bindable var artikelStore: ArtikelKatalogStore
    @Bindable var lagerStore: LagerlisteStore

    @State private var query: String = ""
    @State private var filterKategorie: String? = nil
    @State private var filterHersteller: String? = nil
    @State private var hoveredArtikelID: String? = nil

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

    // MARK: - Computed

    private var gefilterteArtikel: [ArtikelSuchergebnis] {
        var treffer = artikelStore.suche(term: query)
        if let kat = filterKategorie {
            treffer = treffer.filter { $0.artikel.kategorie == kat }
        }
        if let her = filterHersteller {
            treffer = treffer.filter { $0.artikel.hersteller == her }
        }
        return Array(treffer.prefix(300))
    }

    private var kategorienListe: [String] {
        Array(Set(artikelStore.alleArtikel.compactMap(\.kategorie))).sorted()
    }

    private var herstellerListe: [String] {
        Array(Set(artikelStore.alleArtikel.compactMap(\.hersteller))).sorted()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toolbar
            switch artikelStore.state {
            case .idle:
                emptyHint("Artikel werden gleich geladen …")
            case .loading(let n):
                loadingView(n)
            case .notConnected:
                emptyHint("Airtable nicht verbunden — in den Einstellungen verbinden.")
            case .error(let msg):
                emptyHint("Fehler: \(msg)")
            case .empty:
                emptyHint("Keine Artikel im Katalog gefunden.")
            case .content:
                artikelListe
            }
        }
        .task { await artikelStore.load(); await lagerStore.load() }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: MykSpace.s4) {
            // Suchfeld
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                TextField("Bezeichnung, Hersteller, Art.-Nr. …", text: $query)
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
            }
            .padding(MykSpace.s3)
            .background(MykColor.card.color)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            .frame(maxWidth: 320)

            // Kategorie-Filter
            if !kategorienListe.isEmpty {
                Picker("Kategorie", selection: $filterKategorie) {
                    Text("Alle Kategorien").tag(String?.none)
                    ForEach(kategorienListe, id: \.self) { kat in
                        Text(kat).tag(String?.some(kat))
                    }
                }
                .pickerStyle(.menu)
                .font(.mykSmall)
                .frame(maxWidth: 180)
            }

            // Hersteller-Filter
            if !herstellerListe.isEmpty {
                Picker("Hersteller", selection: $filterHersteller) {
                    Text("Alle Hersteller").tag(String?.none)
                    ForEach(herstellerListe, id: \.self) { h in
                        Text(h).tag(String?.some(h))
                    }
                }
                .pickerStyle(.menu)
                .font(.mykSmall)
                .frame(maxWidth: 160)
            }

            Spacer()

            // Reload-Button
            Button {
                Task { await artikelStore.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }
            .buttonStyle(.plain)
            .help("Katalog neu laden")
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s4)
    }

    // MARK: - Artikel-Liste

    private var artikelListe: some View {
        let items = gefilterteArtikel
        return VStack(spacing: 0) {
            // Tabellenkopf
            HStack(spacing: 0) {
                Text("Hersteller").frame(width: 110, alignment: .leading)
                Text("Bezeichnung").frame(maxWidth: .infinity, alignment: .leading)
                Text("Art.-Nr.").frame(width: 120, alignment: .leading)
                Text("EK netto").frame(width: 90, alignment: .trailing)
                Text("VK MYKILOS").frame(width: 100, alignment: .trailing)
                Text("Lager").frame(width: 130, alignment: .center)
                Text("").frame(width: 90)  // Warenkorb-Spalte
            }
            .font(.mykMono(9))
            .foregroundStyle(MykColor.muted.color)
            .padding(.horizontal, MykSpace.s9)
            .padding(.vertical, MykSpace.s2)
            .background(MykColor.paper2.color)

            Divider().overlay(MykColor.line.color)

            if items.isEmpty {
                Text("Keine Treffer\(query.isEmpty ? "" : " für \"\(query)\"")")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(MykSpace.s9)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { ergebnis in
                            ArtikelZeile(
                                ergebnis: ergebnis,
                                lagerTreffer: lagerTreffenFuer(ergebnis.artikel),
                                preisFormatter: Self.preisFormatter,
                                onAddToCart: { warenkorb.addArtikel($0); warenkorb.showPanel = true }
                            )
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
                Text("\(items.count) Artikel angezeigt · \(artikelStore.alleArtikel.count) gesamt")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
                    .padding(.vertical, MykSpace.s3)
                    .padding(.horizontal, MykSpace.s9)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Helpers

    private func lagerTreffenFuer(_ artikel: ArtikelItem) -> AufLagerMatcherResult {
        AufLagerMatcher.suche(artikel: artikel, in: lagerStore.items)
    }

    private func loadingView(_ geladen: Int) -> some View {
        VStack(spacing: MykSpace.s4) {
            Spacer()
            ProgressView("Lade Katalog … \(geladen > 0 ? "\(geladen) Artikel" : "")")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.mykSmall)
            .foregroundStyle(MykColor.muted.color)
            .padding(MykSpace.s9)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ArtikelZeile

@MainActor
private struct ArtikelZeile: View {
    let ergebnis: ArtikelSuchergebnis
    let lagerTreffer: AufLagerMatcherResult
    let preisFormatter: NumberFormatter
    let onAddToCart: (ArtikelItem) -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Text(ergebnis.artikel.hersteller ?? "–")
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)
                .foregroundStyle(MykColor.inkSoft.color)

            Text(ergebnis.artikel.artikelbeschreibung ?? ergebnis.artikel.artikelnummer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

            Text(ergebnis.artikel.artikelnummer)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .foregroundStyle(MykColor.muted.color)

            // EK Netto
            Group {
                if let ek = ergebnis.artikel.ekNetto {
                    Text(preisFormatter.string(from: NSNumber(value: ek)) ?? "–")
                        .foregroundStyle(MykColor.muted.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 90, alignment: .trailing)

            // VK MYKILOS
            Group {
                if let vk = ergebnis.artikel.vkNetto {
                    Text(preisFormatter.string(from: NSNumber(value: vk)) ?? "–")
                        .foregroundStyle(MykColor.tasks.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 100, alignment: .trailing)

            // Auf-Lager-Badge
            lagerBadge
                .frame(width: 130, alignment: .center)

            // Warenkorb-Button
            Button {
                onAddToCart(ergebnis.artikel)
            } label: {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "cart.badge.plus")
                        .font(.mykCaption)
                    Text("Warenkorb")
                        .font(.mykMono(9))
                }
                .foregroundStyle(MykColor.paper.color)
                .padding(.horizontal, MykSpace.s3)
                .padding(.vertical, MykSpace.s2)
                .background(MykColor.tasks.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            }
            .buttonStyle(.plain)
            .frame(width: 90, alignment: .center)
            .opacity(isHovered ? 1.0 : 0.7)
        }
        .font(.mykMono(10))
        .foregroundStyle(MykColor.ink.color)
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(isHovered ? MykColor.paper2.color : Color.clear)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }

    @ViewBuilder
    private var lagerBadge: some View {
        if !lagerTreffer.exakt.isEmpty {
            let bestand = lagerTreffer.exakt.first?.bestand
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.mykMono(9))
                Text(bestand.map { "auf Lager (\($0))" } ?? "auf Lager")
                    .font(.mykMono(9))
                    .lineLimit(1)
            }
            .foregroundStyle(MykColor.positive.color)
        } else if !lagerTreffer.aehnlich.isEmpty {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "circle.dotted")
                    .font(.mykMono(9))
                Text("≈ ähnlich")
                    .font(.mykMono(9))
            }
            .foregroundStyle(MykColor.people.color)
        } else {
            Text("–")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
        }
    }
}

// MARK: - LagerTab
// Kataloge-Tab „Lager": zeigt die 151 Lager-Records (LagerlisteStore) als Tabelle.
// Bezeichnung/Kategorie/Hersteller/Bestand/EK/VK/Quelle, „+ Warenkorb" je Zeile.
@MainActor
struct LagerTab: View {

    @Bindable var warenkorb: WarenkorbState
    @Bindable var lagerStore: LagerlisteStore

    @State private var query: String = ""
    @State private var filterKategorie: String? = nil

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

    private var gefilterteItems: [LagerItem] {
        var items = lagerStore.items
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            items = items.filter {
                $0.bezeichnung.lowercased().contains(q)
                || ($0.hersteller?.lowercased().contains(q) ?? false)
                || ($0.kategorie?.lowercased().contains(q) ?? false)
                || ($0.artikelnummer?.lowercased().contains(q) ?? false)
                || ($0.quelle?.lowercased().contains(q) ?? false)
            }
        }
        if let kat = filterKategorie {
            items = items.filter { $0.kategorie == kat }
        }
        return items
    }

    private var kategorienListe: [String] {
        Array(Set(lagerStore.items.compactMap(\.kategorie))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toolbar
            switch lagerStore.state {
            case .idle:
                emptyHint("Lagerliste wird geladen …")
            case .loading:
                VStack {
                    Spacer()
                    ProgressView("Lade Lager …")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            case .notConnected:
                emptyHint("Airtable nicht verbunden — in den Einstellungen verbinden.")
            case .error(let msg):
                emptyHint("Fehler: \(msg)")
            case .empty:
                emptyHint("Lagerliste leer.")
            case .content:
                lagerTabelle
            }
        }
        .task { await lagerStore.load() }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: MykSpace.s4) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                TextField("Bezeichnung, Hersteller, Art.-Nr. …", text: $query)
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
            }
            .padding(MykSpace.s3)
            .background(MykColor.card.color)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            .frame(maxWidth: 320)

            if !kategorienListe.isEmpty {
                Picker("Kategorie", selection: $filterKategorie) {
                    Text("Alle Kategorien").tag(String?.none)
                    ForEach(kategorienListe, id: \.self) { kat in
                        Text(kat).tag(String?.some(kat))
                    }
                }
                .pickerStyle(.menu)
                .font(.mykSmall)
                .frame(maxWidth: 180)
            }

            Spacer()

            Button {
                Task { await lagerStore.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }
            .buttonStyle(.plain)
            .help("Lagerliste neu laden")
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s4)
    }

    // MARK: - Tabelle

    private var lagerTabelle: some View {
        let items = gefilterteItems
        return VStack(spacing: 0) {
            // Tabellenkopf
            HStack(spacing: 0) {
                Text("Bezeichnung").frame(maxWidth: .infinity, alignment: .leading)
                Text("Kategorie").frame(width: 120, alignment: .leading)
                Text("Hersteller").frame(width: 110, alignment: .leading)
                Text("Bestand").frame(width: 65, alignment: .trailing)
                Text("EK netto").frame(width: 85, alignment: .trailing)
                Text("VK netto").frame(width: 90, alignment: .trailing)
                Text("Quelle").frame(width: 100, alignment: .leading)
                Text("").frame(width: 90)
            }
            .font(.mykMono(9))
            .foregroundStyle(MykColor.muted.color)
            .padding(.horizontal, MykSpace.s9)
            .padding(.vertical, MykSpace.s2)
            .background(MykColor.paper2.color)

            Divider().overlay(MykColor.line.color)

            if items.isEmpty {
                Text("Keine Treffer\(query.isEmpty ? "" : " für \"\(query)\"")")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(MykSpace.s9)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            LagerZeile(
                                item: item,
                                preisFormatter: Self.preisFormatter,
                                onAddToCart: { warenkorb.addLagerItem($0); warenkorb.showPanel = true }
                            )
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
                Text("\(items.count) Einträge · \(lagerStore.items.count) gesamt · AIRTABLE LAGERLISTE")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
                    .padding(.vertical, MykSpace.s3)
                    .padding(.horizontal, MykSpace.s9)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.mykSmall)
            .foregroundStyle(MykColor.muted.color)
            .padding(MykSpace.s9)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - LagerZeile

@MainActor
private struct LagerZeile: View {
    let item: LagerItem
    let preisFormatter: NumberFormatter
    let onAddToCart: (LagerItem) -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Text(item.bezeichnung)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

            Text(item.kategorie ?? "–")
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .foregroundStyle(MykColor.muted.color)

            Text(item.hersteller ?? "–")
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)
                .foregroundStyle(MykColor.inkSoft.color)

            // Bestand
            Group {
                if let b = item.bestand {
                    Text("\(b)")
                        .foregroundStyle(b > 0 ? MykColor.positive.color : MykColor.critical.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 65, alignment: .trailing)

            // EK
            Group {
                if let ek = item.ekNetto {
                    Text(preisFormatter.string(from: NSNumber(value: ek)) ?? "–")
                        .foregroundStyle(MykColor.muted.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 85, alignment: .trailing)

            // VK
            Group {
                if let vk = item.vkNetto {
                    Text(preisFormatter.string(from: NSNumber(value: vk)) ?? "–")
                        .foregroundStyle(MykColor.tasks.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 90, alignment: .trailing)

            Text(item.quelle ?? "–")
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)
                .foregroundStyle(MykColor.faint.color)

            // Warenkorb-Button
            Button {
                onAddToCart(item)
            } label: {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "cart.badge.plus")
                        .font(.mykCaption)
                    Text("Warenkorb")
                        .font(.mykMono(9))
                }
                .foregroundStyle(MykColor.paper.color)
                .padding(.horizontal, MykSpace.s3)
                .padding(.vertical, MykSpace.s2)
                .background(MykColor.drive.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            }
            .buttonStyle(.plain)
            .frame(width: 90, alignment: .center)
            .opacity(isHovered ? 1.0 : 0.7)
        }
        .font(.mykMono(10))
        .foregroundStyle(MykColor.ink.color)
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(isHovered ? MykColor.paper2.color : Color.clear)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}
