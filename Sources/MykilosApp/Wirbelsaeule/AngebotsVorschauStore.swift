import Foundation
import Observation
import MykilosKit

// MARK: - AngebotsVorschauStore (V10, Block G — „Zum Angebot")
//
// Erzeugt aus einem persistierten `WorkBasket` eine **lokale** Angebots-VORSCHAU-PDF
// und legt sie im App-Support-Ordner ab. KEIN Drive-Write (Drive ist read-only, RAIL),
// KEIN sevDesk, keine Postbox — reine lokale Ablage. Der Angebote-Tab liest denselben
// Ordner und zeigt die Vorschauen an.
//
// EISERNE REGEL (Johannes 2026-07-03, `belegfuehrung-extern-regel`): mykilOS stellt NIE
// verbuchungspflichtige Dokumente aus. Das erzeugte PDF ist über Titel + Kopf-Hinweis +
// Fußzeile sichtbar als „Kalkulations-Vorschau — kein offizielles Angebot" beschriftet
// (siehe `AngebotsRenderMapper`). Das verbindliche Angebot entsteht separat in sevDesk.
@MainActor
@Observable
public final class AngebotsVorschauStore {

    /// Eine lokal abgelegte Vorschau-Datei.
    public struct VorschauDatei: Identifiable, Equatable {
        public let url: URL
        public let erstellt: Date
        public var id: String { url.path }
        public var name: String { url.lastPathComponent }
    }

    public private(set) var dateien: [VorschauDatei] = []
    public private(set) var letzterFehler: String?
    /// URL der zuletzt erzeugten Datei (für „gerade erstellt"-Hervorhebung in der UI).
    public private(set) var zuletztErzeugt: URL?

    /// Basisordner aller Vorschauen. Default: `<App-Support>/mykilOS6/AngebotsVorschau/`
    /// (derselbe App-Support-Zweig wie die Produktions-DB). Injizierbar für Tests.
    private let basisOrdner: URL

    public init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.basisOrdner = baseDirectory
        } else {
            let root = AppDatabase.productionURL.deletingLastPathComponent()
            self.basisOrdner = root.appendingPathComponent("AngebotsVorschau", isDirectory: true)
        }
    }

    // MARK: - Ablage-Ort

    private func projektOrdner(_ projektNummer: String) -> URL {
        basisOrdner.appendingPathComponent(Self.dateiSicher(projektNummer), isDirectory: true)
    }

    /// Entfernt Pfad-gefährdende Zeichen aus einem Bezeichner (Ordner-/Dateiname-sicher).
    private static func dateiSicher(_ roh: String) -> String {
        let erlaubt = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        let ersetzt = String(roh.unicodeScalars.map { erlaubt.contains($0) ? Character($0) : "-" })
        return ersetzt.isEmpty ? "unbenannt" : ersetzt
    }

    // MARK: - Lesen

    /// Lädt die vorhandenen Vorschau-PDFs eines Projekts (neueste zuerst).
    public func lade(projektNummer: String) {
        letzterFehler = nil
        let ordner = projektOrdner(projektNummer)
        guard FileManager.default.fileExists(atPath: ordner.path) else {
            dateien = []
            return
        }
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: ordner,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            dateien = urls
                .filter { $0.pathExtension.lowercased() == "pdf" }
                .map { url in
                    let datum = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                        .contentModificationDate ?? .distantPast
                    return VorschauDatei(url: url, erstellt: datum)
                }
                .sorted { $0.erstellt > $1.erstellt }
        } catch {
            dateien = []
            letzterFehler = error.localizedDescription
        }
    }

    // MARK: - Erzeugen

    /// Rendert eine Vorschau-PDF aus dem WorkBasket und legt sie lokal ab.
    /// - Returns: URL der geschriebenen Datei, oder `nil` bei Fehler (`letzterFehler` gesetzt).
    @discardableResult
    public func erzeuge(
        basket: WorkBasket,
        kunde: String,
        projektTitel: String,
        projektNummer: String,
        datum: Date = Date()
    ) -> URL? {
        letzterFehler = nil
        let args = AngebotsRenderMapper.map(
            basket: basket,
            kunde: kunde,
            projektTitel: projektTitel,
            datum: datum
        )
        let pdf = MykPDFRenderer.render(
            title: args.title,
            subtitle: args.subtitle,
            sections: args.sections,
            table: args.table,
            totals: args.totals,
            footerNote: args.footerNote
        )
        guard pdf.isEmpty == false else {
            letzterFehler = "PDF konnte nicht erzeugt werden."
            return nil
        }
        do {
            let ordner = projektOrdner(projektNummer)
            try FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
            // Basisname ohne Endung sanitisieren (der Punkt würde sonst ersetzt), dann ".pdf" anhängen.
            let basisName = "\(AngebotsRenderMapper.angebotsnummer(projektNummer: projektNummer))-\(zeitstempel(datum))"
            let ziel = ordner
                .appendingPathComponent(Self.dateiSicher(basisName))
                .appendingPathExtension("pdf")
            try pdf.write(to: ziel, options: .atomic)
            zuletztErzeugt = ziel
            lade(projektNummer: projektNummer)
            return ziel
        } catch {
            letzterFehler = error.localizedDescription
            return nil
        }
    }

    /// Deterministischer Dateizeitstempel `yyyyMMdd-HHmmss` (lokale Zeit).
    private func zeitstempel(_ datum: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: datum)
    }
}
