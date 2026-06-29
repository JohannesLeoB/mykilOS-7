import SwiftUI
import PDFKit
import AppKit
import MykilosDesign
import MykilosServices

// MARK: - FilePreviewView
// Datei-Vorschau für Drive-Dateien.
// Modus 1 (lokal): Quick Look / PDFKit für lokale Dateien (Finder-URL bekannt).
// Modus 2 (remote): Thumbnail-URL wenn vorhanden (drive.readonly-Scope), sonst Typ-Icon.
// Öffnen: lokal via NSWorkspace.open, remote via webViewLink im Browser.
// Kein Schreiben. Keine Keychain-Daten.
public struct FilePreviewView: View {
    public let file: GoogleDriveFile
    public var showOpenButton: Bool = true
    /// Optionale lokale URL (vom LocalDriveRootResolver aufgelöst).
    public var localURL: URL? = nil
    /// Optionaler Remote-Fallback: liefert die PDF-Bytes (read-only, z. B. Drive
    /// `downloadContent`), wenn die Datei NICHT lokal materialisiert ist. So rendert
    /// die Vorschau ein echtes PDF in-App, ohne den Browser zu öffnen (Mandate D).
    public var remotePDFData: (@Sendable () async -> Data?)? = nil

    public init(file: GoogleDriveFile,
                showOpenButton: Bool = true,
                localURL: URL? = nil,
                remotePDFData: (@Sendable () async -> Data?)? = nil) {
        self.file = file
        self.showOpenButton = showOpenButton
        self.localURL = localURL
        self.remotePDFData = remotePDFData
    }

    @State private var pdfDocument: PDFDocument? = nil
    @State private var loadingPDF = false

    public var body: some View {
        VStack(spacing: MykSpace.s4) {
            previewContent
            info
            openButton
        }
        .padding(MykSpace.s5)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.paper2.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
        .task { await loadPDF() }
    }

    // MARK: - Preview

    @ViewBuilder
    private var previewContent: some View {
        if let pdf = pdfDocument {
            PDFThumbnailKitView(document: pdf)
                .frame(maxWidth: 280, maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        } else if loadingPDF {
            ProgressView().scaleEffect(0.7).frame(height: 60)
        } else if let thumbURL = file.thumbnailLink.flatMap({ URL(string: $0) }) {
            AsyncImage(url: thumbURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                case .failure: typeIcon
                case .empty: ProgressView().scaleEffect(0.7).frame(height: 60)
                @unknown default: typeIcon
                }
            }
        } else {
            typeIcon
        }
    }

    private var typeIcon: some View {
        Image(systemName: file.iconName)
            .font(.system(size: 40))
            .foregroundStyle(MykColor.drive.color)
            .frame(height: 60)
    }

    // MARK: - Info

    private var info: some View {
        VStack(spacing: 2) {
            Text(file.name)
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            HStack(spacing: MykSpace.s2) {
                Text(file.typeLabel)
                if let size = file.fileSize, size > 0 {
                    Text("·")
                    Text(file.fileSizeLabel)
                }
                if localURL != nil {
                    Text("·")
                    Text("lokal")
                        .foregroundStyle(MykColor.positive.color)
                }
            }
            .font(.mykMono(9))
            .foregroundStyle(MykColor.muted.color)
        }
    }

    // MARK: - Open Button

    @ViewBuilder
    private var openButton: some View {
        if showOpenButton {
            if let local = localURL, FileManager.default.fileExists(atPath: local.path) {
                Button {
                    NSWorkspace.shared.open(local)
                } label: {
                    Label("Im Finder öffnen", systemImage: "folder")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.drive.color)
                }
                .buttonStyle(.plain)
            } else if let link = file.webViewLink, let url = URL(string: link) {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Label("Im Browser öffnen", systemImage: "arrow.up.right.square")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.drive.color)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - PDF-Ladelogik

    private func loadPDF() async {
        guard file.mimeType == "application/pdf" else { return }
        // 1. Lokal materialisiert → direkt aus der Datei rendern (schnell, kein Netz).
        if let local = localURL, FileManager.default.fileExists(atPath: local.path) {
            loadingPDF = true
            let doc = await Task.detached(priority: .utility) { PDFDocument(url: local) }.value
            pdfDocument = doc
            loadingPDF = false
            return
        }
        // 2. Nicht lokal → optionaler Remote-Fallback (Drive downloadContent, read-only):
        //    echtes PDF in-App statt Browser/Thumbnail.
        if let remotePDFData {
            loadingPDF = true
            let data = await remotePDFData()
            let doc = await Task.detached(priority: .utility) { data.flatMap { PDFDocument(data: $0) } }.value
            pdfDocument = doc
            loadingPDF = false
        }
    }
}

// MARK: - PDFThumbnailKitView
// Zeigt die erste Seite eines PDFDocuments via PDFKit (AppKit-Bridge).
private struct PDFThumbnailKitView: NSViewRepresentable {
    let document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePage
        view.displayBox = .mediaBox
        view.backgroundColor = .clear
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
    }
}
