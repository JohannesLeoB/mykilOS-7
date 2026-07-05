import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - OffersTabView (Post-Akt 5, Aufgabe 10; zwei Spalten seit Live-Wiring)
// Die „Angebote"-Tab der Projekt-Detailseite. Zeigt die zwei realen Drive-
// Unterordner eines Projekts nebeneinander: "04 ausgehende Angebote" und
// "05 eingehende Angebote" — nicht mehr eine Namens-Heuristik über den ganzen
// Projektordner (die frühere Variante hätte Belege in diesen Unterordnern nie
// gefunden, weil `listFolder` nicht rekursiv ist).
//
// Read-only: nur Metadaten + Link zum Öffnen im Browser, nie Schreiben. Alle
// Renderstates über den geteilten `WidgetContainer`; Quelle bleibt sichtbar.
struct OffersTabView: View {
    let projectID: String
    let driveFolderID: String?
    /// Optionaler expliziter lokaler Pfad-Hinweis (Airtable `driveFolderPath`).
    var driveFolderPath: String? = nil

    // Block G („Zum Angebot"): nur im Projekt-Kontext gesetzt. Fehlt der Store,
    // bleibt die Vorschau-Sektion aus (z. B. im globalen Angebote-Modul).
    var workBasketStore: WorkBasketStore? = nil
    var kundeName: String? = nil
    var projektTitel: String? = nil

    @State private var loader = OffersLoader()
    @State private var searchText = ""
    @State private var sortByDate = true   // true = neueste zuerst, false = Name A–Z
    // Galerie-Flug: Liste ⇄ Galerie + Kachelgröße (pro Ansicht gemerkt).
    @AppStorage("angebote.galerie") private var galerieAn = false
    @AppStorage("angebote.kachel") private var kachelSeiteRaw: Double = 150
    @State private var viewerFile: GoogleDriveFile?

    @State private var vorschauStore = AngebotsVorschauStore()
    @State private var vorschauMeldung: String?

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s7) {
            if workBasketStore != nil { vorschauSektion }
            driveBelege
        }
        .task(id: driveFolderID) {
            await loader.load(rootFolderID: driveFolderID)
        }
        .task(id: projectID) {
            if workBasketStore != nil { vorschauStore.lade(projektNummer: projectID) }
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 64)   // Platz für SaveStateBar
        .sheet(item: $viewerFile) { file in
            let items = galerieEintraege.map { eintrag in
                DocumentViewerItem(
                    file: eintrag.file, localURL: eintrag.localURL,
                    remoteContent: { try? await GoogleDriveClient().downloadContent(fileID: eintrag.file.id) })
            }
            let startIndex = items.firstIndex(where: { $0.id == file.id }) ?? 0
            DocumentViewerView(items: items, initialIndex: startIndex, onClose: { viewerFile = nil })
                .frame(minWidth: 820, minHeight: 680)
        }
    }

    private var driveBelege: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                if case .content = loader.renderState { searchAndSort }
                if galerieAn {
                    DateiGalerieGrid(
                        eintraege: galerieEintraege, kachelSeite: kachelSeite,
                        onPreview: { viewerFile = $0.file },
                        onOpen: { LocalDriveRootResolver.shared.openFile(
                            localURL: $0.localURL,
                            fallbackURL: $0.file.webViewLink.flatMap { URL(string: $0) }) })
                } else {
                    columns
                }
            }
        }
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "GOOGLE DRIVE  ·  \(loader.incoming.count + loader.outgoing.count) BELEGE"
        default:       "GOOGLE DRIVE"
        }
    }

    // MARK: - Block G: Kalkulations-Vorschau aus dem Warenkorb (lokal, kein Drive/sevDesk)

    private var vorschauSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            HStack {
                SourceChip(kind: .cash)
                Text("Angebots-Vorschau").mykWidgetTitle()
                Spacer()
                Button {
                    erzeugeVorschau()
                } label: {
                    Label("Zum Angebot", systemImage: "doc.badge.plus")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s5)
                        .padding(.vertical, MykSpace.s3)
                        .background(MykColor.cash.color)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                }
                .buttonStyle(.plain)
                .help("Erzeugt eine lokale Kalkulations-Vorschau (PDF) aus dem persistierten Warenkorb")
                .accessibilityLabel("Angebots-Vorschau aus Warenkorb erzeugen")
            }

            Text(AngebotsRenderMapper.vorschauFussnote)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.drive.color)

            if let vorschauMeldung {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "info.circle").font(.mykCaption).foregroundStyle(MykColor.muted.color)
                    Text(vorschauMeldung).font(.mykSmall).foregroundStyle(MykColor.muted.color)
                }
            }

            if vorschauStore.dateien.isEmpty {
                Text("Noch keine Vorschau erzeugt.")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.faint.color)
            } else {
                VStack(spacing: 0) {
                    ForEach(vorschauStore.dateien) { datei in
                        VorschauZeile(datei: datei, istNeu: datei.url == vorschauStore.zuletztErzeugt)
                        if datei.id != vorschauStore.dateien.last?.id {
                            Divider().overlay(MykColor.line.color.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(MykSpace.s6)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
    }

    private func erzeugeVorschau() {
        vorschauMeldung = nil
        guard let workBasketStore else { return }
        do {
            let baskets = try workBasketStore.alle(projektNummer: projectID)
            guard let basket = baskets.max(by: { $0.erstellt < $1.erstellt }),
                  basket.picks.isEmpty == false else {
                vorschauMeldung = "Kein Warenkorb mit Positionen für dieses Projekt — erst im Warenkorb-Widget/Intake anlegen."
                return
            }
            let url = vorschauStore.erzeuge(
                basket: basket,
                kunde: kundeName ?? "—",
                projektTitel: projektTitel ?? projectID,
                projektNummer: projectID
            )
            if url == nil {
                vorschauMeldung = vorschauStore.letzterFehler ?? "Vorschau konnte nicht erstellt werden."
            }
        } catch {
            vorschauMeldung = error.localizedDescription
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Angebote & Rechnungen").mykWidgetTitle()
            Spacer()
            if case .content = loader.renderState { refreshButton }
            else if case .error = loader.renderState { retryButton }
            else if case .permissionRequired = loader.renderState { retryButton }
        }
    }

    private var searchAndSort: some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: "magnifyingglass")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
            TextField("Dateiname suchen…", text: $searchText)
                .font(.mykSmall)
                .textFieldStyle(.plain)
            Spacer()
            if galerieAn { KachelGroessenSlider(kachelSeite: kachelSeite) }
            ansichtsToggle
            Button {
                sortByDate.toggle()
            } label: {
                Label(sortByDate ? "Datum" : "Name",
                      systemImage: sortByDate ? "calendar" : "textformat.abc")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
            .buttonStyle(.plain)
            .help(sortByDate ? "Sortierung: Neueste zuerst — klicken für Name A–Z" : "Sortierung: Name A–Z — klicken für Datum")
            .accessibilityLabel(sortByDate ? "Sortierung: Neueste zuerst — klicken für Name A–Z" : "Sortierung: Name A–Z — klicken für Datum")
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, MykSpace.s2)
        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.line.color.opacity(0.18)))
    }

    private func filtered(_ offers: [ClassifiedOffer]) -> [ClassifiedOffer] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = q.isEmpty ? offers : offers.filter { $0.file.name.localizedCaseInsensitiveContains(q) }
        return sortByDate
            ? base.sorted { ($0.file.modifiedAt ?? .distantPast) > ($1.file.modifiedAt ?? .distantPast) }
            : base.sorted { $0.file.name.localizedCompare($1.file.name) == .orderedAscending }
    }

    private var kachelSeite: Binding<CGFloat> {
        Binding(get: { CGFloat(kachelSeiteRaw) }, set: { kachelSeiteRaw = Double($0) })
    }

    // Alle sichtbaren Belege (eingehend + ausgehend) flach als Galerie-Einträge.
    private var galerieEintraege: [DateiGalerieGrid.Eintrag] {
        let ein = filtered(loader.incoming).map { (offer: $0, dir: "eingehend") }
        let aus = filtered(loader.outgoing).map { (offer: $0, dir: "ausgehend") }
        return (ein + aus).map { pair in
            DateiGalerieGrid.Eintrag(
                file: pair.offer.file,
                subtitle: "\(pair.offer.type.label) · \(pair.dir)",
                localURL: LocalDriveRootResolver.shared.localURL(
                    forFileID: pair.offer.file.id, fileName: pair.offer.file.name,
                    inProjectFolderID: driveFolderID ?? "", explicitProjectPath: driveFolderPath))
        }
    }

    // Liste ⇄ Galerie (Finder-Stil-Segment).
    private var ansichtsToggle: some View {
        HStack(spacing: 0) {
            toggleTaste(aktiv: galerieAn == false, icon: "list.bullet") { galerieAn = false }
            toggleTaste(aktiv: galerieAn, icon: "square.grid.2x2") { galerieAn = true }
        }
        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color)
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
    }

    private func toggleTaste(aktiv: Bool, icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.mykCaption)
                .foregroundStyle(aktiv ? MykColor.paper.color : MykColor.muted.color)
                .padding(.horizontal, MykSpace.s3).padding(.vertical, MykSpace.s2)
                .background(aktiv ? MykColor.ink.color : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private var refreshButton: some View {
        Button {
            Task { await loader.load(rootFolderID: driveFolderID) }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.mykCaption)
                .foregroundStyle(MykColor.drive.color)
        }
        .buttonStyle(.plain)
        .help("Aktualisieren")
        .accessibilityLabel("Aktualisieren")
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(rootFolderID: driveFolderID) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.drive.color)
    }

    private var columns: some View {
        HStack(alignment: .top, spacing: MykSpace.s7) {
            OfferColumn(
                title: "Eingehende Angebote",
                offers: filtered(loader.incoming),
                folderFound: loader.incomingFolderFound,
                eingehend: true,
                projektNummer: projectID,
                workBasketStore: workBasketStore,
                projectFolderID: driveFolderID,
                projectFolderPath: driveFolderPath
            )
            Divider().overlay(MykColor.line.color.opacity(0.6))
            OfferColumn(
                title: "Ausgehende Angebote",
                offers: filtered(loader.outgoing),
                folderFound: loader.outgoingFolderFound,
                eingehend: false,
                projektNummer: projectID,
                workBasketStore: workBasketStore,
                projectFolderID: driveFolderID,
                projectFolderPath: driveFolderPath
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - OfferColumn
// Zeigt Belege gruppiert nach Dokumenttyp (Angebote / Aufträge / Rechnungen / …).
private struct OfferColumn: View {
    let title: String
    let offers: [ClassifiedOffer]
    let folderFound: Bool
    var eingehend: Bool = true
    var projektNummer: String = ""
    var workBasketStore: WorkBasketStore? = nil
    var projectFolderID: String? = nil
    var projectFolderPath: String? = nil

    // Gruppiert nach Typ, in stabiler Anzeigereihenfolge (OfferDocumentType.rawValue).
    private var groups: [(type: OfferDocumentType, offers: [ClassifiedOffer])] {
        Dictionary(grouping: offers, by: \.type)
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (type: $0.key, offers: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text("\(title) · \(offers.count)")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
            if folderFound == false {
                Text("Ordner nicht gefunden")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            } else if offers.isEmpty {
                Text("Keine Belege")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            } else {
                ForEach(groups, id: \.type) { group in
                    typeSection(group.type, group.offers)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func typeSection(_ type: OfferDocumentType, _ offers: [ClassifiedOffer]) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("\(type.label) · \(offers.count)")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.cash.color)
                .padding(.top, MykSpace.s2)
            VStack(spacing: 0) {
                ForEach(offers) { offer in
                    OfferRow(file: offer.file, meta: offer,
                             eingehend: eingehend,
                             projektNummer: projektNummer,
                             workBasketStore: workBasketStore,
                             projectFolderID: projectFolderID,
                             projectFolderPath: projectFolderPath)
                    if offer.id != offers.last?.id {
                        Divider().overlay(MykColor.line.color.opacity(0.6))
                    }
                }
            }
        }
    }
}

// MARK: - VorschauZeile (Block G — lokale Vorschau-PDF)
private struct VorschauZeile: View {
    let datei: AngebotsVorschauStore.VorschauDatei
    let istNeu: Bool

    var body: some View {
        Button {
            NSWorkspace.shared.open(datei.url)
        } label: {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: "doc.richtext")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.cash.color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(datei.name)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.ink.color)
                        .lineLimit(1)
                    Text(datei.erstellt.formatted(.relative(presentation: .named)))
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                }
                if istNeu {
                    Text("NEU")
                        .font(.mykMono(8))
                        .foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s2)
                        .padding(.vertical, 1)
                        .background(MykColor.positive.color)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.faint.color)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, MykSpace.s3)
        .contextMenu {
            Button("Im Finder zeigen") {
                NSWorkspace.shared.activateFileViewerSelecting([datei.url])
            }
        }
    }
}

// OffersLoader ist in OffersLoader.swift — intern, testbar.

// MARK: - OfferRow
private struct OfferRow: View {
    let file: GoogleDriveFile
    var meta: ClassifiedOffer? = nil
    var eingehend: Bool = true
    var projektNummer: String = ""
    var workBasketStore: WorkBasketStore? = nil
    var projectFolderID: String? = nil
    var projectFolderPath: String? = nil

    @Environment(AppState.self) private var appState
    @State private var showPreview = false
    @State private var showPositions = false
    @State private var resolvedLocalURL: URL?

    // Positions-Extraktion nur für echte PDFs anbieten.
    private var isPDF: Bool {
        file.mimeType == "application/pdf" || (file.name as NSString).pathExtension.lowercased() == "pdf"
    }

    // Belegnummer + Version als kompakte Kennung (z.B. "2026-0151 · v3").
    private var metaLine: String? {
        guard let meta else { return nil }
        var parts: [String] = []
        if let nr = meta.belegNummer { parts.append(nr) }
        if let v = meta.version { parts.append(v) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // Lokaler Pfad der Datei im Projektbaum (xattr-/Namens-Auflösung). `nil`, wenn
    // nicht lokal materialisiert → dann greift der Remote-PDF-Fallback bzw. Browser.
    private func resolveLocalURL() -> URL? {
        guard let projectFolderID, projectFolderID.isEmpty == false else { return nil }
        return LocalDriveRootResolver.shared.localURL(
            forFileID: file.id, fileName: file.name,
            inProjectFolderID: projectFolderID, explicitProjectPath: projectFolderPath
        )
    }

    // Read-only Remote-Fallback: Datei-Bytes aus Drive (kein Schreiben), damit die
    // Vorschau auch nicht-materialisierte Belege echt rendert statt Safari zu öffnen.
    // Versorgt PDF-Thumbnail UND volle Dokumentenvorschau (S3).
    private func remoteContent() -> (@Sendable () async -> Data?)? {
        let fileID = file.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            Button {
                resolvedLocalURL = resolveLocalURL()
                showPreview.toggle()
            } label: {
                Image(systemName: file.iconName)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.cash.color)
                    .frame(width: 20)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPreview, arrowEdge: .trailing) {
                FilePreviewView(file: file, localURL: resolvedLocalURL, remoteContent: remoteContent())
                    .frame(width: 300)
                    .padding(MykSpace.s2)
            }

            Button {
                // Lokal-zuerst öffnen (macOS-Vorschau), sonst Browser-Fallback — nie blind Safari.
                let local = resolveLocalURL()
                let fallback = file.webViewLink.flatMap { URL(string: $0) }
                LocalDriveRootResolver.shared.openFile(localURL: local, fallbackURL: fallback)
            } label: {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.ink.color)
                            .lineLimit(1)
                        HStack(spacing: MykSpace.s2) {
                            if let metaLine {
                                Text(metaLine)
                                    .font(.mykMono(9.5))
                                    .foregroundStyle(MykColor.cash.color)
                            }
                            if let modifiedAt = file.modifiedAt {
                                Text(modifiedAt.formatted(.relative(presentation: .named)))
                                    .font(.mykMono(9.5))
                                    .foregroundStyle(MykColor.muted.color)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.faint.color)
                }
            }
            .buttonStyle(.plain)

            // Flaggschiff-Feature sichtbar statt nur im Rechtsklick-Menü versteckt
            // (Johannes-Feedback 2026-07-04: nicht auffindbar).
            if isPDF {
                Button {
                    showPositions = true
                } label: {
                    Label("Positionen", systemImage: "text.line.first.and.arrowtriangle.forward")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s3)
                        .padding(.vertical, 4)
                        .background(MykColor.cash.color)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                }
                .buttonStyle(.plain)
                .help("Positionen aus diesem PDF-Angebot herauslösen und in den Warenkorb legen")
                .accessibilityLabel("Positionen aus PDF herauslösen")
            }
        }
        .padding(.vertical, MykSpace.s3)
        .contextMenu {
            if isPDF {
                Button("Positionen herauslösen") { showPositions = true }
                Divider()
            }
            Button("Im Finder zeigen") {
                if let local = resolveLocalURL() {
                    LocalDriveRootResolver.shared.revealInFinder(localURL: local)
                } else if let link = file.webViewLink, let url = URL(string: link) {
                    NSWorkspace.shared.open(url)
                }
            }
            if let link = file.webViewLink, let url = URL(string: link) {
                Button("Im Browser öffnen") { NSWorkspace.shared.open(url) }
            }
        }
        .sheet(isPresented: $showPositions) {
            OfferPositionsSheet(
                file: file,
                onTake: workBasketStore.map { store in
                    { (paged: OfferPositionPDFReader.PagedPosition, index: Int) in
                        let p = paged.position
                        let preis = p.netPrice.map { ($0 as NSDecimalNumber).doubleValue }
                        Task {
                            // Fehler nicht stumm schlucken (Ultra-Review): der WorkBasketStore
                            // macht ihn über seinen SaveState im Warenkorb-Widget sichtbar.
                            do {
                                try await store.fuegePositionHinzu(
                                    projektNummer: projektNummer,
                                    bezeichnung: p.title.isEmpty ? file.name : p.title,
                                    menge: max(1, Int((p.quantity ?? 1).rounded())),   // runden statt abschneiden (Ultra-Review)
                                    ekEinzel: eingehend ? preis : nil,
                                    vkEinzel: eingehend ? nil : preis,
                                    objektID: "\(file.id)-\(paged.pageNumber)-\(index)",
                                    attribute: positionsAttribute(p, quelle: file.name, seite: paged.pageNumber, eingehend: eingehend))
                            } catch {
                                MykLog.lifecycle.error("Warenkorb-Anhängen fehlgeschlagen: \(String(describing: error), privacy: .public)")
                            }
                        }
                    }
                },
                learningStore: appState.learningStore,
                onClose: { showPositions = false })
        }
    }
}
