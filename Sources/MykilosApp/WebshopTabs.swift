import SwiftUI
import AppKit
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - ArtikelShopTab
// Kataloge-Tab „Artikel / Shop": lädt den Live-Artikel-Katalog (ArtikelKatalogStore,
// ~13.419 Records), sucht/filtert clientseitig, zeigt Auf-Lager-Badge per AufLagerMatcher.
// „+ Warenkorb"-Button je Artikel → WarenkorbState.addArtikel.
// Lager-Daten kommen aus dem gemeinsamen LagerlisteStore (übergeben aus KatalogeView).
//
// Phase 4: Pagination (25/50/100 pro Seite), Liste/Kachel-Umschalter, AsyncImage-Vorschaubilder.
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
    @State private var anzahlProSeite: Int = 50
    @State private var seite: Int = 0           // 0-basiert
    @State private var zeigeKacheln: Bool = false
    // Preislisten-Detailvorschau: Klick auf einen Artikel öffnet ein Detail-Sheet
    // (großes Bild, alle Felder, EK/VK/Marge, „In den Warenkorb"). Nil = kein Sheet.
    @State private var detailArtikel: ArtikelItem? = nil

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

    // MARK: - Computed

    /// Alle gefilterten Artikel (ohne Seitenbegrenzung) — Basis für Seitennavigation.
    private var allGefilterteArtikel: [ArtikelSuchergebnis] {
        var treffer = artikelStore.suche(term: query)
        if let kat = filterKategorie {
            treffer = treffer.filter { $0.artikel.kategorie == kat }
        }
        if let her = filterHersteller {
            treffer = treffer.filter { $0.artikel.hersteller == her }
        }
        return treffer
    }

    /// Aktuelle Seite der gefilterten Artikel.
    private var aktuelleSeiteArtikel: [ArtikelSuchergebnis] {
        let all = allGefilterteArtikel
        let start = seite * anzahlProSeite
        guard start < all.count else { return [] }
        let end = min(start + anzahlProSeite, all.count)
        return Array(all[start..<end])
    }

    private var seitenAnzahl: Int {
        max(1, Int(ceil(Double(allGefilterteArtikel.count) / Double(anzahlProSeite))))
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
                VStack(spacing: MykSpace.s4) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.mykDisplay)
                        .foregroundStyle(MykColor.critical.color)
                    Text("Fehler beim Laden des Katalogs")
                        .font(.mykHeadline)
                        .foregroundStyle(MykColor.ink.color)
                    Text(msg)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)
                        .multilineTextAlignment(.center)
                    Button("Erneut versuchen") { Task { await artikelStore.reload() } }
                        .buttonStyle(.plain)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s5)
                        .padding(.vertical, MykSpace.s3)
                        .background(MykColor.critical.color)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(MykSpace.s9)
            case .empty:
                emptyHint("Keine Artikel im Katalog gefunden — Airtable-Verbindung und Tabellen-Name prüfen.")
            case .content:
                if zeigeKacheln {
                    artikelKacheln
                } else {
                    artikelListe
                }
            }
        }
        .task { await artikelStore.load(); await lagerStore.load() }
        .onChange(of: query) { seite = 0 }
        .onChange(of: filterKategorie) { seite = 0 }
        .onChange(of: filterHersteller) { seite = 0 }
        .onChange(of: anzahlProSeite) { seite = 0 }
        .sheet(item: $detailArtikel) { artikel in
            ArtikelDetailSheet(
                artikel: artikel,
                lagerTreffer: lagerTreffenFuer(artikel),
                preisFormatter: Self.preisFormatter,
                onAddToCart: {
                    warenkorb.addArtikel(artikel)
                    warenkorb.showPanel = true
                    detailArtikel = nil
                },
                onClose: { detailArtikel = nil }
            )
        }
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
            .frame(maxWidth: 300)

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
                .frame(maxWidth: 170)
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
                .frame(maxWidth: 150)
            }

            Spacer()

            // Ansicht-Umschalter: Liste ↔ Kacheln
            HStack(spacing: 0) {
                Button {
                    zeigeKacheln = false
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.mykSmall)
                        .foregroundStyle(zeigeKacheln ? MykColor.muted.color : MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s3)
                        .padding(.vertical, MykSpace.s2)
                        .background(zeigeKacheln ? MykColor.card.color : MykColor.tasks.color)
                }
                .buttonStyle(.plain)
                .help("Listenansicht")
                .accessibilityLabel("Listenansicht")

                Button {
                    zeigeKacheln = true
                } label: {
                    Image(systemName: "square.grid.2x2")
                        .font(.mykSmall)
                        .foregroundStyle(zeigeKacheln ? MykColor.paper.color : MykColor.muted.color)
                        .padding(.horizontal, MykSpace.s3)
                        .padding(.vertical, MykSpace.s2)
                        .background(zeigeKacheln ? MykColor.tasks.color : MykColor.card.color)
                }
                .buttonStyle(.plain)
                .help("Kachelansicht")
                .accessibilityLabel("Kachelansicht")
            }
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))

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
            .accessibilityLabel("Katalog neu laden")
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s4)
    }

    // MARK: - Artikel-Liste (Tabellenansicht)

    private var artikelListe: some View {
        let items = aktuelleSeiteArtikel
        return VStack(spacing: 0) {
            // Tabellenkopf
            HStack(spacing: 0) {
                Text("").frame(width: 44)   // Bild-Spalte
                Text("Hersteller").frame(width: 100, alignment: .leading)
                Text("Bezeichnung").frame(maxWidth: .infinity, alignment: .leading)
                Text("Art.-Nr.").frame(width: 110, alignment: .leading)
                Text("EK netto").frame(width: 85, alignment: .trailing)
                Text("VK MYKILOS").frame(width: 95, alignment: .trailing)
                Text("Lager").frame(width: 120, alignment: .center)
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
                        ForEach(items) { ergebnis in
                            ArtikelZeile(
                                ergebnis: ergebnis,
                                lagerTreffer: lagerTreffenFuer(ergebnis.artikel),
                                preisFormatter: Self.preisFormatter,
                                onAddToCart: { warenkorb.addArtikel($0); warenkorb.showPanel = true },
                                onOpenDetail: { detailArtikel = $0 }
                            )
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
            }
            paginierungsLeiste
        }
    }

    // MARK: - Artikel-Kacheln

    private var artikelKacheln: some View {
        let items = aktuelleSeiteArtikel
        return VStack(spacing: 0) {
            if items.isEmpty {
                Text("Keine Treffer\(query.isEmpty ? "" : " für \"\(query)\"")")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(MykSpace.s9)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 200, maximum: 260), spacing: MykSpace.s5)
                    ], spacing: MykSpace.s5) {
                        ForEach(items) { ergebnis in
                            ArtikelKachel(
                                ergebnis: ergebnis,
                                lagerTreffer: lagerTreffenFuer(ergebnis.artikel),
                                preisFormatter: Self.preisFormatter,
                                onAddToCart: { warenkorb.addArtikel($0); warenkorb.showPanel = true },
                                onOpenDetail: { detailArtikel = $0 }
                            )
                        }
                    }
                    .padding(MykSpace.s9)
                }
            }
            paginierungsLeiste
        }
    }

    // MARK: - Paginierung

    private var paginierungsLeiste: some View {
        HStack(spacing: MykSpace.s4) {
            // Einträge-pro-Seite
            HStack(spacing: MykSpace.s2) {
                Text("Pro Seite:")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
                Picker("", selection: $anzahlProSeite) {
                    Text("25").tag(25)
                    Text("50").tag(50)
                    Text("100").tag(100)
                }
                .pickerStyle(.menu)
                .font(.mykMono(9))
                .frame(width: 60)
            }

            // Status-Text
            let total = allGefilterteArtikel.count
            let start = seite * anzahlProSeite + 1
            let end = min((seite + 1) * anzahlProSeite, total)
            Text("\(total > 0 ? "\(start)–\(end)" : "0") von \(total) · \(artikelStore.alleArtikel.count) gesamt")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)

            Spacer()

            // Seiten-Navigation
            Button {
                seite = 0
            } label: {
                Image(systemName: "chevron.backward.2")
                    .font(.mykMono(9))
            }
            .buttonStyle(.plain)
            .disabled(seite == 0)
            .foregroundStyle(seite == 0 ? MykColor.faint.color : MykColor.muted.color)

            Button {
                if seite > 0 { seite -= 1 }
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.mykMono(9))
            }
            .buttonStyle(.plain)
            .disabled(seite == 0)
            .foregroundStyle(seite == 0 ? MykColor.faint.color : MykColor.muted.color)

            Text("Seite \(seite + 1) / \(seitenAnzahl)")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
                .frame(minWidth: 80, alignment: .center)

            Button {
                if seite < seitenAnzahl - 1 { seite += 1 }
            } label: {
                Image(systemName: "chevron.forward")
                    .font(.mykMono(9))
            }
            .buttonStyle(.plain)
            .disabled(seite >= seitenAnzahl - 1)
            .foregroundStyle(seite >= seitenAnzahl - 1 ? MykColor.faint.color : MykColor.muted.color)

            Button {
                seite = seitenAnzahl - 1
            } label: {
                Image(systemName: "chevron.forward.2")
                    .font(.mykMono(9))
            }
            .buttonStyle(.plain)
            .disabled(seite >= seitenAnzahl - 1)
            .foregroundStyle(seite >= seitenAnzahl - 1 ? MykColor.faint.color : MykColor.muted.color)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(MykColor.paper2.color)
    }

    // MARK: - Helpers

    private func lagerTreffenFuer(_ artikel: ArtikelItem) -> AufLagerMatcherResult {
        AufLagerMatcher.suche(artikel: artikel, in: lagerStore.items)
    }

    private func loadingView(_ geladen: Int) -> some View {
        VStack(spacing: MykSpace.s4) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Lade Katalog … \(geladen > 0 ? "\(geladen) Datensätze geladen" : "Verbinde mit Airtable")")
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

// MARK: - ArtikelZeile (Listenansicht)

@MainActor
private struct ArtikelZeile: View {
    let ergebnis: ArtikelSuchergebnis
    let lagerTreffer: AufLagerMatcherResult
    let preisFormatter: NumberFormatter
    let onAddToCart: (ArtikelItem) -> Void
    let onOpenDetail: (ArtikelItem) -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // Miniatur-Vorschaubild (44×36, AsyncImage)
            ArtikelMiniaturBild(url: ergebnis.artikel.produktbildURL)
                .frame(width: 44)

            Text(ergebnis.artikel.hersteller ?? "–")
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)
                .foregroundStyle(MykColor.inkSoft.color)

            Text(ergebnis.artikel.artikelbeschreibung ?? ergebnis.artikel.artikelnummer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

            Text(ergebnis.artikel.artikelnummer)
                .frame(width: 110, alignment: .leading)
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
            .frame(width: 85, alignment: .trailing)

            // VK MYKILOS
            Group {
                if let vk = ergebnis.artikel.vkNetto {
                    Text(preisFormatter.string(from: NSNumber(value: vk)) ?? "–")
                        .foregroundStyle(MykColor.tasks.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 95, alignment: .trailing)

            // Auf-Lager-Badge
            lagerBadge
                .frame(width: 120, alignment: .center)

            // Warenkorb-Button
            Button {
                onAddToCart(ergebnis.artikel)
            } label: {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "cart.badge.plus")
                        .font(.mykCaption)
                    Text("+ Korb")
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
        .padding(.vertical, MykSpace.s2)
        .background(isHovered ? MykColor.paper2.color : Color.clear)
        // Klick auf die Zeile (außerhalb des +Korb-Buttons) → Detail-Vorschau.
        .contentShape(Rectangle())
        .onTapGesture { onOpenDetail(ergebnis.artikel) }
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
                Text(bestand.map { "(\($0))" } ?? "✓")
                    .font(.mykMono(9))
                    .lineLimit(1)
            }
            .foregroundStyle(MykColor.positive.color)
        } else if !lagerTreffer.aehnlich.isEmpty {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "circle.dotted")
                    .font(.mykMono(9))
                Text("ähnlich")
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

// MARK: - ArtikelMiniaturBild (shared)
// Kleines Vorschaubild für Listenansicht (44×36) und Kachelansicht.
// AsyncImage mit Platzhalter — kein Layout-Rückblick ohne Bild.
private struct ArtikelMiniaturBild: View {
    let url: String?
    var groesse: CGFloat = 36

    var body: some View {
        Group {
            if let urlStr = url, let imageURL = URL(string: urlStr) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        platzhalter
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.5)
                    @unknown default:
                        platzhalter
                    }
                }
            } else {
                platzhalter
            }
        }
        .frame(width: groesse, height: groesse)
        .background(MykColor.paper2.color)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var platzhalter: some View {
        Image(systemName: "photo")
            .font(.mykMono(10))
            .foregroundStyle(MykColor.faint.color)
    }
}

// MARK: - ArtikelDetailSheet (Preislisten-Detailvorschau)
// Klick auf einen Artikel (Zeile oder Kachel) öffnet dieses Sheet: großes Produktbild,
// alle Stammdaten, EK/VK/Marge und „In den Warenkorb". Read-only auf die Artikel-Daten —
// kein Schreiben in die Airtable-Artikel-Tabelle (die ist Daniels Hoheit, read-only).
@MainActor
private struct ArtikelDetailSheet: View {
    let artikel: ArtikelItem
    let lagerTreffer: AufLagerMatcherResult
    let preisFormatter: NumberFormatter
    let onAddToCart: () -> Void
    let onClose: () -> Void

    /// Marge in % = (VK − EK) / VK · 100 — nur wenn beide Preise > 0.
    private var margeProzent: Double? {
        guard let ek = artikel.ekNetto, let vk = artikel.vkNetto, vk > 0 else { return nil }
        return (vk - ek) / vk * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            kopfzeile
            produktbild
            titelBlock
            preisBlock
            lagerZeile
            Spacer(minLength: 0)
            aktionen
        }
        .padding(MykSpace.s7)
        .frame(width: 480, height: 640)
        .background(MykColor.paper.color)
    }

    // MARK: Kopfzeile (Hersteller + Schließen)
    private var kopfzeile: some View {
        HStack {
            Text((artikel.hersteller ?? "Artikel").uppercased())
                .font(.mykMono(11))
                .foregroundStyle(MykColor.muted.color)
                .tracking(1.5)
            Spacer()
            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.faint.color)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Detailvorschau schließen")
        }
    }

    // MARK: Produktbild (groß, klickbar → Browser)
    @ViewBuilder
    private var produktbild: some View {
        Group {
            if let urlStr = artikel.produktbildURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    case .failure: bildPlatzhalter
                    case .empty: ProgressView()
                    @unknown default: bildPlatzhalter
                    }
                }
                .onTapGesture { NSWorkspace.shared.open(url) }
                .help("Produktbild im Browser öffnen")
            } else {
                bildPlatzhalter
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(MykColor.paper2.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .stroke(MykColor.line.color, lineWidth: 1)
        )
    }

    private var bildPlatzhalter: some View {
        Image(systemName: "photo")
            .font(.mykDisplay)
            .foregroundStyle(MykColor.faint.color)
    }

    // MARK: Titel + Meta-Chips
    private var titelBlock: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text(artikel.artikelbeschreibung ?? artikel.artikelnummer)
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: MykSpace.s2) {
                metaChip(icon: "number", text: artikel.artikelnummer)
                if let kat = artikel.kategorie, !kat.isEmpty {
                    metaChip(icon: "tag", text: kat)
                }
            }
        }
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: MykSpace.s2) {
            Image(systemName: icon).font(.mykMono(9))
            Text(text).font(.mykMono(10)).lineLimit(1)
        }
        .foregroundStyle(MykColor.muted.color)
        .padding(.horizontal, MykSpace.s3)
        .padding(.vertical, MykSpace.s2)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
    }

    // MARK: Preis-Block (EK / VK / Marge)
    private var preisBlock: some View {
        HStack(spacing: MykSpace.s3) {
            preisFeld(titel: "EK NETTO", wert: artikel.ekNetto, farbe: MykColor.muted)
            preisFeld(titel: "VK MYKILOS", wert: artikel.vkNetto, farbe: MykColor.tasks)
            margeFeld
        }
    }

    private func preisFeld(titel: String, wert: Double?, farbe: MykColor) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text(titel).font(.mykMono(9)).foregroundStyle(MykColor.faint.color).tracking(1)
            Text(wert.flatMap { preisFormatter.string(from: NSNumber(value: $0)) } ?? "–")
                .font(.mykHeadline)
                .foregroundStyle(wert == nil ? MykColor.faint.color : farbe.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
    }

    private var margeFeld: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("MARGE").font(.mykMono(9)).foregroundStyle(MykColor.faint.color).tracking(1)
            Text(margeProzent.map { String(format: "%.0f %%", $0) } ?? "–")
                .font(.mykHeadline)
                .foregroundStyle(margeProzent == nil ? MykColor.faint.color : MykColor.positive.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
    }

    // MARK: Lager-Hinweis
    @ViewBuilder
    private var lagerZeile: some View {
        if !lagerTreffer.exakt.isEmpty {
            let bestand = lagerTreffer.exakt.first?.bestand
            lagerHinweis(icon: "checkmark.circle.fill",
                         text: bestand.map { "Auf Lager (\($0) Stück)" } ?? "Auf Lager",
                         farbe: MykColor.positive)
        } else if !lagerTreffer.aehnlich.isEmpty {
            lagerHinweis(icon: "circle.dotted",
                         text: "Ähnlicher Artikel im Lager",
                         farbe: MykColor.people)
        } else {
            lagerHinweis(icon: "shippingbox",
                         text: "Nicht am Lager — Bestellartikel",
                         farbe: MykColor.muted)
        }
    }

    private func lagerHinweis(icon: String, text: String, farbe: MykColor) -> some View {
        HStack(spacing: MykSpace.s2) {
            Image(systemName: icon).font(.mykCaption)
            Text(text).font(.mykSmall)
        }
        .foregroundStyle(farbe.color)
    }

    // MARK: Aktionen
    private var aktionen: some View {
        HStack(spacing: MykSpace.s3) {
            Button { onClose() } label: {
                Text("Schließen")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(.horizontal, MykSpace.s5)
                    .padding(.vertical, MykSpace.s3)
                    .background(MykColor.card.color)
                    .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button { onAddToCart() } label: {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "cart.badge.plus").font(.mykCaption)
                    Text("In den Warenkorb").font(.mykSmall)
                }
                .foregroundStyle(MykColor.paper.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MykSpace.s3)
                .background(MykColor.tasks.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - ArtikelKachel (Kachelansicht)

@MainActor
private struct ArtikelKachel: View {
    let ergebnis: ArtikelSuchergebnis
    let lagerTreffer: AufLagerMatcherResult
    let preisFormatter: NumberFormatter
    let onAddToCart: (ArtikelItem) -> Void
    let onOpenDetail: (ArtikelItem) -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            // Vorschaubild
            ArtikelMiniaturBild(url: ergebnis.artikel.produktbildURL, groesse: 80)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 80)

            // Hersteller
            if let hersteller = ergebnis.artikel.hersteller {
                Text(hersteller)
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
                    .lineLimit(1)
            }

            // Bezeichnung
            Text(ergebnis.artikel.artikelbeschreibung ?? ergebnis.artikel.artikelnummer)
                .font(.mykSmall)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Artikelnummer
            Text(ergebnis.artikel.artikelnummer)
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Preise
            HStack {
                if let vk = ergebnis.artikel.vkNetto {
                    Text(preisFormatter.string(from: NSNumber(value: vk)) ?? "–")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.tasks.color)
                } else {
                    Text("–")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.faint.color)
                }
                Spacer()
                // Lager-Indikator
                if !lagerTreffer.exakt.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.positive.color)
                }
            }

            // Warenkorb-Button
            Button {
                onAddToCart(ergebnis.artikel)
            } label: {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "cart.badge.plus")
                        .font(.mykCaption)
                    Text("In den Warenkorb")
                        .font(.mykMono(9))
                }
                .foregroundStyle(MykColor.paper.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MykSpace.s2)
                .background(MykColor.tasks.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.85)
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .stroke(isHovered ? MykColor.tasks.color.opacity(0.5) : MykColor.line.color, lineWidth: 1)
        )
        // Klick auf die Kachel (außerhalb des Buttons) → Detail-Vorschau.
        .contentShape(Rectangle())
        .onTapGesture { onOpenDetail(ergebnis.artikel) }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
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
            .accessibilityLabel("Lagerliste neu laden")
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

// MARK: - WarenkorbListeTab
// Kataloge-Tab „Warenkörbe": zeigt alle Airtable-Einträge aus „Warenkörbe"
// (tblhZujm3Ig6hlafX, Base appdxTeT6bhSBmwx5) als fortlaufende Liste.
//
// Read-only Ansicht mit Wiederherstellung: Klick auf einen Eintrag lädt seine
// Positionen (aus Positionen-JSON) in den lokalen WarenkorbState → Weiterbearbeitung
// im Artikel/Shop-Tab. Speichern bleibt append-only über CartStore.
//
// Autor-Feld: noch nicht in der Tabelle (geplant für Backend/Daniel).
@MainActor
struct WarenkorbListeTab: View {

    @Bindable var warenkorb: WarenkorbState
    @Bindable var store: WarenkorbListeStore

    @State private var query: String = ""
    @State private var filterStatus: String? = nil   // nil = alle, "Aktuell", "Archiviert"
    // Fix (2026-07-02, Johannes/Screenshot 17.48/17.49): „Vorschau"/„Wiederherstellen"
    // öffneten ein LEERES weißes Sheet. Ursache waren ZWEI `.sheet(isPresented:)`-Modifier
    // am selben View (bekannter SwiftUI-Konflikt → eines präsentiert leer) plus die Race,
    // dass `ausgewahlterEintrag` beim Aufbau des Sheet-Inhalts noch nil sein konnte
    // (`if let` schlug fehl → EmptyView). Jetzt EIN einziges `.sheet(item:)`, das den
    // Eintrag samt Modus (Vorschau/Wiederherstellen) garantiert gebunden mitführt.
    @State private var sheetKontext: WarenkorbSheetKontext? = nil

    private static let datumsFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

    private var gefilterteEintraege: [WarenkorbEintrag] {
        var items = store.eintraege
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            items = items.filter {
                $0.bezeichnung.lowercased().contains(q)
                || ($0.projekt?.lowercased().contains(q) ?? false)
                || $0.status.lowercased().contains(q)
            }
        }
        if let s = filterStatus {
            items = items.filter { $0.status == s }
        }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toolbar
            switch store.state {
            case .idle:
                emptyHint("Warenkörbe werden geladen …")
            case .loading:
                VStack {
                    Spacer()
                    ProgressView("Lade Warenkörbe …")
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
                emptyHint("Noch keine Warenkörbe gespeichert.")
            case .content:
                warenkorbListe
            }
        }
        .task { await store.load() }
        // EIN einziges item-getriebenes Sheet für Vorschau UND Wiederherstellen.
        // Der `previewOnly`-Modus steckt im Kontext, damit ein Klick auf „Vorschau"
        // nie versehentlich den aktiven Warenkorb ersetzt. Weil `.sheet(item:)` erst
        // präsentiert, sobald der Kontext gesetzt ist, ist der Eintrag garantiert da —
        // kein leeres weißes Sheet mehr.
        .sheet(item: $sheetKontext) { kontext in
            WarenkorbWiederherstellungsSheet(
                eintrag: kontext.eintrag,
                warenkorb: warenkorb,
                datumsFormatter: Self.datumsFormatter,
                preisFormatter: Self.preisFormatter,
                previewOnly: kontext.previewOnly,
                onDismiss: { sheetKontext = nil }
            )
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: MykSpace.s4) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                TextField("Bezeichnung, Projekt, Status …", text: $query)
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
            .frame(maxWidth: 300)

            Picker("Status", selection: $filterStatus) {
                Text("Alle").tag(String?.none)
                Text("Aktuell").tag(String?.some("Aktuell"))
                Text("Archiviert").tag(String?.some("Archiviert"))
            }
            .pickerStyle(.menu)
            .font(.mykSmall)
            .frame(maxWidth: 130)

            Spacer()

            Button {
                Task { await store.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }
            .buttonStyle(.plain)
            .help("Warenkörbe neu laden")
            .accessibilityLabel("Warenkörbe neu laden")
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s4)
    }

    // MARK: - Liste

    private var warenkorbListe: some View {
        let items = gefilterteEintraege
        return VStack(spacing: 0) {
            // Tabellenkopf
            HStack(spacing: 0) {
                Text("Datum").frame(width: 140, alignment: .leading)
                Text("Bezeichnung").frame(maxWidth: .infinity, alignment: .leading)
                Text("Projekt").frame(width: 140, alignment: .leading)
                Text("Status").frame(width: 85, alignment: .center)
                Text("V.").frame(width: 35, alignment: .center)
                Text("Pos.").frame(width: 40, alignment: .trailing)
                Text("EK netto").frame(width: 90, alignment: .trailing)
                Text("VK netto").frame(width: 90, alignment: .trailing)
                Text("").frame(width: 150) // Vorschau + Wiederherstellen
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
                        ForEach(items) { eintrag in
                            WarenkorbZeile(
                                eintrag: eintrag,
                                datumsFormatter: Self.datumsFormatter,
                                preisFormatter: Self.preisFormatter,
                                onVorschau: {
                                    sheetKontext = WarenkorbSheetKontext(eintrag: eintrag, previewOnly: true)
                                },
                                onWiederherstellen: {
                                    sheetKontext = WarenkorbSheetKontext(eintrag: eintrag, previewOnly: false)
                                }
                            )
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
                Text("\(items.count) Einträge · \(store.eintraege.count) gesamt · AIRTABLE WARENKÖRBE")
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

// MARK: - WarenkorbZeile

@MainActor
private struct WarenkorbZeile: View {
    let eintrag: WarenkorbEintrag
    let datumsFormatter: DateFormatter
    let preisFormatter: NumberFormatter
    let onVorschau: () -> Void
    let onWiederherstellen: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if let d = eintrag.erstelltAm {
                    Text(datumsFormatter.string(from: d))
                        .foregroundStyle(MykColor.muted.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 140, alignment: .leading)
            .lineLimit(1)

            Text(eintrag.bezeichnung)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .foregroundStyle(MykColor.ink.color)

            Text(eintrag.projekt ?? "–")
                .frame(width: 140, alignment: .leading)
                .lineLimit(1)
                .foregroundStyle(MykColor.muted.color)

            Text(eintrag.status)
                .font(.mykMono(9))
                .foregroundStyle(eintrag.istAktuell ? MykColor.positive.color : MykColor.faint.color)
                .frame(width: 85, alignment: .center)

            Text("v\(eintrag.version)")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 35, alignment: .center)

            Group {
                if let n = eintrag.anzahlPositionen {
                    Text("\(n)")
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 40, alignment: .trailing)

            Group {
                if let ek = eintrag.gesamtEK {
                    Text(preisFormatter.string(from: NSNumber(value: ek)) ?? "–")
                        .foregroundStyle(MykColor.muted.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 90, alignment: .trailing)

            Group {
                if let vk = eintrag.gesamtVK {
                    Text(preisFormatter.string(from: NSNumber(value: vk)) ?? "–")
                        .foregroundStyle(MykColor.tasks.color)
                } else {
                    Text("–").foregroundStyle(MykColor.faint.color)
                }
            }
            .frame(width: 90, alignment: .trailing)

            if eintrag.positionenJSON != nil {
                HStack(spacing: MykSpace.s2) {
                    // Neutrale Vorschau — öffnet dieselben Positionen read-only,
                    // ändert den aktiven Warenkorb NIE (Härtung 2026-07-02).
                    // Erster Nutzer des neuen MykIconButton (A11y: Pflicht-Label).
                    MykIconButton("eye", label: "Vorschau — lädt nichts in den aktiven Warenkorb",
                                  style: .bordered) {
                        onVorschau()
                    }

                    Button {
                        onWiederherstellen()
                    } label: {
                        HStack(spacing: MykSpace.s2) {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.mykCaption)
                            Text("Wiederherstellen")
                                .font(.mykMono(9))
                        }
                        .foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s3)
                        .padding(.vertical, MykSpace.s2)
                        .background(MykColor.cash.color)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered ? 1.0 : 0.7)
                }
                .frame(width: 150, alignment: .center)
            } else {
                Text("–")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
                    .frame(width: 150, alignment: .center)
            }
        }
        .font(.mykMono(10))
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(isHovered ? MykColor.paper2.color : Color.clear)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}

// MARK: - WarenkorbSheetKontext
// Identifiable-Kontext, der Eintrag + Modus (Vorschau/Wiederherstellen) bündelt und
// so das item-getriebene Sheet speist. Bewusst pro Modus eine eigene `id`, damit ein
// direkter Wechsel Vorschau→Wiederherstellen (oder umgekehrt) das Sheet neu aufbaut.
private struct WarenkorbSheetKontext: Identifiable {
    let eintrag: WarenkorbEintrag
    let previewOnly: Bool
    var id: String { "\(previewOnly ? "preview" : "restore")-\(eintrag.id)" }
}

// MARK: - WarenkorbWiederherstellungsSheet
@MainActor
private struct WarenkorbWiederherstellungsSheet: View {
    let eintrag: WarenkorbEintrag
    @Bindable var warenkorb: WarenkorbState
    let datumsFormatter: DateFormatter
    let preisFormatter: NumberFormatter
    /// Härtung (2026-07-02): true = reine Ansicht, „In Warenkorb laden" entfällt komplett —
    /// der aktive Warenkorb wird nie angefasst. Deckt die fehlende Vorschau-Funktion ab,
    /// ohne den bestehenden, funktionierenden Wiederherstellungs-Pfad zu verändern.
    var previewOnly: Bool = false
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text(previewOnly ? "Warenkorb — Vorschau" : "Warenkorb wiederherstellen")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                Text(eintrag.bezeichnung)
                    .font(.mykBody)
                    .foregroundStyle(MykColor.cash.color)
                if let datum = eintrag.erstelltAm {
                    Text("Erstellt: \(datumsFormatter.string(from: datum)) · Version \(eintrag.version)")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                }
            }

            Divider().overlay(MykColor.line.color)

            if let items = eintrag.decodedItems(), !items.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: MykSpace.s2) {
                        ForEach(items) { item in
                            HStack {
                                Text("\(item.menge)×")
                                    .font(.mykMono(9))
                                    .foregroundStyle(MykColor.muted.color)
                                    .frame(width: 28, alignment: .trailing)
                                Text(item.bezeichnung)
                                    .font(.mykSmall)
                                    .foregroundStyle(MykColor.ink.color)
                                Spacer()
                                if let vk = item.vkNetto {
                                    Text(preisFormatter.string(from: NSNumber(value: vk * Double(item.menge))) ?? "–")
                                        .font(.mykMono(9))
                                        .foregroundStyle(MykColor.tasks.color)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)

                Divider().overlay(MykColor.line.color)
            } else {
                // Kein leeres Nichts: klarer Hinweis, wenn dieser Warenkorb keine
                // (dekodierbaren) Positionen mitbringt — statt eines weißen Sheets.
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    Label("Keine Positionen hinterlegt", systemImage: "tray")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.ink.color)
                    Text("Für diesen Warenkorb liegen keine (lesbaren) Positionen vor. "
                         + "Er wurde vermutlich ohne Positionen-JSON gespeichert.")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, MykSpace.s4)

                Divider().overlay(MykColor.line.color)
            }

            if previewOnly {
                Text("Reine Vorschau — der aktive Warenkorb wird NICHT verändert.")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Dieser Warenkorb wird in deinen aktiven Warenkorb geladen. Danach kannst du Artikel ergänzen und einen neuen Warenkorb speichern (append-only — der alte bleibt erhalten).")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: MykSpace.s4) {
                Spacer()
                Button(previewOnly ? "Schließen" : "Abbrechen") { onDismiss() }
                    .buttonStyle(.plain)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)

                if previewOnly == false {
                    Button("In Warenkorb laden") {
                        if let items = eintrag.decodedItems() {
                            warenkorb.leeren()
                            for item in items {
                                warenkorb.addWarenkorbItem(item)
                            }
                            warenkorb.showPanel = true
                        }
                        onDismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s5)
                    .padding(.vertical, MykSpace.s3)
                    .background(MykColor.cash.color)
                    .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    .disabled(eintrag.positionenJSON == nil)
                }
            }
        }
        .padding(MykSpace.s9)
        // Feste Mindestgröße, damit das Sheet auf macOS nie auf einen leeren
        // weißen Kasten kollabiert (auch bei leeren Positionen).
        .frame(minWidth: 480, idealWidth: 520, maxWidth: 560, minHeight: 360)
        .background(MykColor.paper.color)
    }
}
