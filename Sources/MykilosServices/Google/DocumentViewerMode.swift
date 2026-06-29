import Foundation

// MARK: - DocumentViewerMode (S3, pure/testbar)
// Bestimmt aus dem MIME-Typ, wie eine Drive-Datei voll dargestellt wird. Reine
// Foundation-Logik (kein UI) → in MykilosServices, damit testbar (das App-Target
// hat kein Test-Target). Der DocumentViewerView (App) rendert je Modus.
public enum DocumentViewerMode: Equatable, Sendable {
    case pdf          // PDFKit, mehrseitig scrollbar
    case image        // NSImage
    case quicklook    // macOS QuickLook (Office, Text, viele Formate) — braucht lokale Datei
    case browserOnly  // Google-native (Docs/Sheets/Slides) → nur im Browser sinnvoll

    public static func classify(mimeType: String) -> DocumentViewerMode {
        if mimeType == "application/pdf" { return .pdf }
        if mimeType.hasPrefix("image/") { return .image }
        if mimeType.hasPrefix("application/vnd.google-apps") { return .browserOnly }
        return .quicklook
    }
}
