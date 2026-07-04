import SwiftUI
import PDFKit
import AppKit
import Quartz          // QLPreviewView (QuickLook)
import MykilosDesign
import MykilosServices

// MARK: - DocumentViewerItem (Galerie-Flug · Blättern/Diashow)
// Ein Eintrag einer blätterbaren Sammlung — Datei + ihre lokale/remote Inhaltsquelle,
// identisch zu dem, was DocumentViewerView vorher als lose Parameter bekam.
public struct DocumentViewerItem: Identifiable, Sendable {
    public let file: GoogleDriveFile
    public let localURL: URL?
    public let remoteContent: (@Sendable () async -> Data?)?
    public var id: String { file.id }

    public init(file: GoogleDriveFile, localURL: URL? = nil,
                remoteContent: (@Sendable () async -> Data?)? = nil) {
        self.file = file
        self.localURL = localURL
        self.remoteContent = remoteContent
    }
}

// MARK: - DocumentViewerView (S3, Galerie-Flug) — volle Dokumentenvorschau
// DocumentViewerMode (Klassifizierung) liegt testbar in MykilosServices.
// Mehrseitiger PDF-Viewer (PDFKit), NSImage für Bilder, QuickLook für sonstige Typen.
// Quelle: lokale Datei (LocalDriveRootResolver) ODER read-only Drive-Bytes (downloadContent,
// braucht drive.readonly → M2). Alle Zustände sind sichtbar: laden / fertig / leer / Fehler /
// Verbindung-nötig. Schreibt NIE; öffnet zur Not im Browser.
//
// Blättern/Diashow: nimmt optional eine ganze Sammlung + Startindex — ←/→ (oder die Header-
// Pfeile) wechseln ohne zu schließen, Leertaste startet/pausiert eine Diashow (Auto-Advance,
// wrapt am Ende zurück zum Anfang). Der alte Einzeldatei-Init bleibt als Komfort-Wrapper
// bestehen (Sammlung mit genau einem Eintrag) — bestehende Aufrufer bleiben unverändert.
@MainActor
public struct DocumentViewerView: View {
    @State private var items: [DocumentViewerItem]
    @State private var index: Int
    var onClose: () -> Void

    public init(file: GoogleDriveFile, localURL: URL? = nil,
                remoteContent: (@Sendable () async -> Data?)? = nil,
                onClose: @escaping () -> Void = {}) {
        self.init(items: [DocumentViewerItem(file: file, localURL: localURL, remoteContent: remoteContent)],
                  initialIndex: 0, onClose: onClose)
    }

    public init(items: [DocumentViewerItem], initialIndex: Int = 0, onClose: @escaping () -> Void = {}) {
        self._items = State(initialValue: items)
        self._index = State(initialValue: min(max(0, initialIndex), max(0, items.count - 1)))
        self.onClose = onClose
    }

    private var current: DocumentViewerItem { items[index] }
    private var file: GoogleDriveFile { current.file }
    private var localURL: URL? { current.localURL }
    private var remoteContent: (@Sendable () async -> Data?)? { current.remoteContent }
    private var kannBlaettern: Bool { items.count > 1 }

    private enum Phase: Equatable {
        case loading
        case pdf(PDFDocument)
        case image(NSImage)
        case quicklook(URL)
        case browserOnly
        case needsConnection
        case failed(String)
    }
    @State private var phase: Phase = .loading
    @State private var diashowLaeuft = false

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)
            content
        }
        .frame(minWidth: 640, minHeight: 520)
        .background(MykColor.paper.color)
        .task(id: file.id) { await load() }
        .focusable()
        .onKeyPress(.leftArrow) { blaettere(-1); return .handled }
        .onKeyPress(.rightArrow) { blaettere(1); return .handled }
        .onKeyPress(.space) {
            guard kannBlaettern else { return .ignored }
            diashowLaeuft.toggle()
            return .handled
        }
        .task(id: diashowLaeuft) {
            guard diashowLaeuft else { return }
            while diashowLaeuft {
                try? await Task.sleep(for: .seconds(3.5))
                guard diashowLaeuft, Task.isCancelled == false else { return }
                blaettere(1, wrap: true)
            }
        }
    }

    // MARK: Blättern/Diashow

    private func blaettere(_ delta: Int, wrap: Bool = false) {
        guard kannBlaettern else { return }
        var next = index + delta
        if wrap {
            next = (next % items.count + items.count) % items.count
        } else {
            next = min(max(0, next), items.count - 1)
        }
        guard next != index else { return }
        index = next
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: file.iconName).font(.mykHeadline).foregroundStyle(MykColor.drive.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(file.name).font(.mykBody).foregroundStyle(MykColor.ink.color).lineLimit(1)
                HStack(spacing: MykSpace.s2) {
                    Text(file.typeLabel).font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                    if kannBlaettern {
                        Text("· \(index + 1) / \(items.count)").font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                    }
                }
            }
            Spacer()
            if kannBlaettern { blaetternControls }
            if let link = file.webViewLink, let url = URL(string: link) {
                Button { NSWorkspace.shared.open(url) } label: {
                    Label("Im Browser", systemImage: "arrow.up.right.square").font(.mykSmall)
                }.buttonStyle(.plain).foregroundStyle(MykColor.drive.color)
            }
            Button { onClose() } label: {
                Image(systemName: "xmark.circle.fill").font(.mykHeadline).foregroundStyle(MykColor.faint.color)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s4)
    }

    private var blaetternControls: some View {
        HStack(spacing: MykSpace.s3) {
            Button { blaettere(-1) } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(index == 0)
            Button {
                diashowLaeuft.toggle()
            } label: {
                Image(systemName: diashowLaeuft ? "pause.fill" : "play.fill")
            }
            .help(diashowLaeuft ? "Diashow pausieren (Leertaste)" : "Diashow starten (Leertaste)")
            Button { blaettere(1) } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(index == items.count - 1)
        }
        .buttonStyle(.plain)
        .font(.mykCaption)
        .foregroundStyle(MykColor.drive.color)
    }

    // MARK: Content / Zustände

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            centered { ProgressView("Lade Dokument …").font(.mykSmall).foregroundStyle(MykColor.muted.color) }
        case .pdf(let doc):
            FullPDFKitView(document: doc)
        case .image(let img):
            ScrollView([.horizontal, .vertical]) {
                Image(nsImage: img).resizable().scaledToFit().padding(MykSpace.s5)
            }
        case .quicklook(let url):
            QuickLookView(url: url)
        case .browserOnly:
            hint(icon: "globe", title: "Google-Dokument",
                 text: "Dieses Format (Google Docs/Sheets/Slides) wird am besten im Browser geöffnet.")
        case .needsConnection:
            hint(icon: "lock.circle", title: "Kein Inhaltszugriff",
                 text: "Die Datei liegt nicht lokal vor und der Drive-Inhalt ist (noch) nicht freigegeben. Google in den Einstellungen neu verbinden (drive.readonly) oder im Browser öffnen.")
        case .failed(let reason):
            hint(icon: "exclamationmark.triangle", title: "Vorschau fehlgeschlagen", text: reason, critical: true)
        }
    }

    private func centered<V: View>(@ViewBuilder _ inner: () -> V) -> some View {
        VStack { Spacer(); inner(); Spacer() }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func hint(icon: String, title: String, text: String, critical: Bool = false) -> some View {
        VStack(spacing: MykSpace.s4) {
            Image(systemName: icon).font(.mykDisplay)
                .foregroundStyle(critical ? MykColor.critical.color : MykColor.faint.color)
            Text(title).font(.mykHeadline).foregroundStyle(MykColor.muted.color)
            Text(text).font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .multilineTextAlignment(.center).frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(MykSpace.s9)
    }

    // MARK: Laden

    private func load() async {
        phase = .loading
        let mode = DocumentViewerMode.classify(mimeType: file.mimeType)
        if mode == .browserOnly { phase = .browserOnly; return }

        // 1. Lokale Datei bevorzugen (kein Netz).
        if let local = localURL, FileManager.default.fileExists(atPath: local.path) {
            await render(mode: mode, url: local)
            return
        }
        // 2. Read-only Drive-Inhalt → in Temp-Datei materialisieren, dann anzeigen.
        guard let remoteContent else { phase = .needsConnection; return }
        guard let data = await remoteContent(), data.isEmpty == false else { phase = .needsConnection; return }
        do {
            let url = try Self.tempURL(for: file.name, data: data)
            await render(mode: mode, url: url)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func render(mode: DocumentViewerMode, url: URL) async {
        switch mode {
        case .pdf:
            if let doc = await Task.detached(priority: .userInitiated, operation: { PDFDocument(url: url) }).value {
                phase = .pdf(doc)
            } else { phase = .failed("PDF konnte nicht gelesen werden.") }
        case .image:
            if let img = NSImage(contentsOf: url) { phase = .image(img) }
            else { phase = .failed("Bild konnte nicht gelesen werden.") }
        case .quicklook:
            phase = .quicklook(url)
        case .browserOnly:
            phase = .browserOnly
        }
    }

    // MARK: - Reine, testbare Bausteine

    /// Schreibt Bytes in eine Temp-Datei mit dem Originalnamen (→ korrekte Endung für QuickLook).
    static func tempURL(for name: String, data: Data) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("mykilos-preview", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let safe = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = dir.appendingPathComponent(safe.isEmpty ? "dokument" : safe)
        try data.write(to: url, options: .atomic)
        return url
    }
}

// MARK: - FullPDFKitView — mehrseitiger, scrollbarer PDF-Viewer
private struct FullPDFKitView: NSViewRepresentable {
    let document: PDFDocument
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        return view
    }
    func updateNSView(_ nsView: PDFView, context: Context) { nsView.document = document }
}

// MARK: - QuickLookView — macOS QuickLook für beliebige lokale Dateitypen
private struct QuickLookView: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal) ?? QLPreviewView()
        view.previewItem = url as NSURL
        return view
    }
    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = url as NSURL
    }
}
