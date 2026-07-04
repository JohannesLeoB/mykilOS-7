import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - GlobalOfferColumn
// Eine Richtungs-Spalte der globalen „Alle Angebote"-Ansicht (Eingehend | Ausgehend).
// Innerhalb nach Dokumenttyp gruppiert, eigenständig scrollbar. Jede Zeile trägt ihre
// echte Projektzuordnung — so ist pro Beleg sichtbar, zu welchem Projekt er gehört.
// Aus AllOffersView.swift herausgelöst (Datei-Länge unter der 400-Zeilen-Grenze halten).
struct GlobalOfferColumn: View {
    let title: String
    let offers: [AllOffersCollector.AggregatedOffer]
    /// Task A (Dev-Checkout-Exporter): optionaler Warenkorb-Kontext für „In Warenkorb".
    var warenkorb: WarenkorbState? = nil

    private var groups: [(type: OfferDocumentType, offers: [AllOffersCollector.AggregatedOffer])] {
        Dictionary(grouping: offers, by: \.offer.type)
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (type: $0.key, offers: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            HStack(spacing: MykSpace.s3) {
                Text(title.uppercased())
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.drive.color)
                Spacer()
                Text("\(offers.count)")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.faint.color)
            }
            if offers.isEmpty {
                Text("Keine Belege")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(.top, MykSpace.s2)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: MykSpace.s3) {
                        ForEach(groups, id: \.type) { group in
                            typeSection(group.type, group.offers)
                        }
                    }
                    .padding(.trailing, MykSpace.s2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func typeSection(
        _ type: OfferDocumentType,
        _ offers: [AllOffersCollector.AggregatedOffer]
    ) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("\(type.label) · \(offers.count)")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.cash.color)
                .padding(.top, MykSpace.s2)
            VStack(spacing: 0) {
                ForEach(offers) { offer in
                    AllOfferRow(item: offer, warenkorb: warenkorb)
                    if offer.id != offers.last?.id {
                        Divider().overlay(MykColor.line.color.opacity(0.5))
                    }
                }
            }
        }
    }
}

// MARK: - AllOfferRow
// Spiegelt OfferRow (Projekt-Tab): lokale Vorschau zuerst, sonst Drive-Bytes,
// Klick → FilePreviewView-Popover (mit Vollvorschau-Button), Kontextmenü.
struct AllOfferRow: View {
    let item: AllOffersCollector.AggregatedOffer
    /// Task A (Dev-Checkout-Exporter): optionaler Warenkorb-Kontext für „In Warenkorb".
    var warenkorb: WarenkorbState? = nil

    @Environment(AppState.self) private var appState
    @State private var showPreview = false
    @State private var showPositions = false
    @State private var resolvedLocalURL: URL?
    @State private var isHovered = false

    private var file: GoogleDriveFile { item.offer.file }

    private var isPDF: Bool {
        file.mimeType == "application/pdf" || (file.name as NSString).pathExtension.lowercased() == "pdf"
    }

    // Führt mit der echten Projektzuordnung (Titel · Nummer). Richtung + Typ zeigt
    // schon die Spalte bzw. die Typ-Sektion — hier bewusst nicht doppelt.
    private var metaLine: String {
        var parts: [String] = [item.projectTitle, item.projectNumber]
        if let nr = item.offer.belegNummer { parts.append(nr) }
        if let v = item.offer.version { parts.append(v) }
        if let modifiedAt = file.modifiedAt {
            parts.append(modifiedAt.formatted(.relative(presentation: .named)))
        }
        return parts.joined(separator: " · ")
    }

    private func resolveLocalURL() -> URL? {
        guard item.projectFolderID.isEmpty == false else { return nil }
        return LocalDriveRootResolver.shared.localURL(
            forFileID: file.id, fileName: file.name,
            inProjectFolderID: item.projectFolderID, explicitProjectPath: nil)
    }

    private func remoteContent() -> (@Sendable () async -> Data?)? {
        let fileID = file.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    var body: some View {
        Button {
            resolvedLocalURL = resolveLocalURL()
            showPreview.toggle()
        } label: {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: file.iconName)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.cash.color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.ink.color)
                        .lineLimit(1)
                    Text(metaLine)
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "eye")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.faint.color)
            }
            .padding(.vertical, MykSpace.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .overlay(alignment: .trailing) {
            if let warenkorb {
                MykIconButton("cart.badge.plus", label: "In Warenkorb", style: .bordered) {
                    warenkorb.addAngebot(
                        fileID: file.id,
                        bezeichnung: file.name,
                        belegNummer: item.offer.belegNummer,
                        eingehend: item.direction == .incoming
                    )
                    warenkorb.showPanel = true
                }
                .opacity(isHovered ? 1.0 : 0.55)
                .padding(.trailing, 24)
            }
        }
        .popover(isPresented: $showPreview, arrowEdge: .trailing) {
            FilePreviewView(file: file, localURL: resolvedLocalURL, remoteContent: remoteContent())
                .frame(width: 320)
                .padding(MykSpace.s2)
        }
        .overlay(alignment: .trailing) {
            // Flaggschiff-Feature sichtbar statt nur im Rechtsklick-Menü versteckt
            // (Johannes-Feedback 2026-07-04: nicht auffindbar).
            if isPDF {
                Button {
                    showPositions = true
                } label: {
                    Image(systemName: "text.line.first.and.arrowtriangle.forward")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.cash.color)
                }
                .buttonStyle(.bordered)
                .help("Positionen aus diesem PDF-Angebot herauslösen und in den Warenkorb legen")
                .accessibilityLabel("Positionen aus PDF herauslösen")
                .opacity(isHovered ? 1.0 : 0.55)
                .padding(.trailing, warenkorb != nil ? 60 : 24)
            }
        }
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
            // WICHTIG (Bugfix 2026-07-04): herausgelöste Positionen gehören in den echten,
            // persistenten Projekt-Warenkorb (`WorkBasketStore`) — NICHT in den flüchtigen,
            // rein session-lokalen `WarenkorbState` dieser globalen Ansicht (der ist für
            // "ganzes Angebot als Zeile" / Dev-Checkout gedacht, überlebt keinen Neustart und
            // taucht im echten Projekt-Warenkorb nie auf). Gleicher Zielspeicher wie im
            // projektbezogenen Angebote-Tab (OffersTabView.OfferRow).
            OfferPositionsSheet(
                file: file,
                onTake: { (paged: OfferPositionPDFReader.PagedPosition, index: Int) in
                    let p = paged.position
                    let preis = p.netPrice.map { ($0 as NSDecimalNumber).doubleValue }
                    let eingehend = item.direction == .incoming
                    let projektNummer = item.projectNumber
                    Task {
                        do {
                            try await appState.workBaskets.fuegePositionHinzu(
                                projektNummer: projektNummer,
                                bezeichnung: p.title.isEmpty ? file.name : p.title,
                                menge: max(1, Int((p.quantity ?? 1).rounded())),
                                ekEinzel: eingehend ? preis : nil,
                                vkEinzel: eingehend ? nil : preis,
                                objektID: "\(file.id)-\(paged.pageNumber)-\(index)",
                                attribute: positionsAttribute(p, quelle: file.name, seite: paged.pageNumber, eingehend: eingehend))
                        } catch {
                            MykLog.lifecycle.error("Warenkorb-Anhängen fehlgeschlagen: \(String(describing: error), privacy: .public)")
                        }
                    }
                },
                learningStore: appState.learningStore,
                onClose: { showPositions = false })
        }
    }
}
