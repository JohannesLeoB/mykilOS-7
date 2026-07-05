import Foundation
import Observation

/// Eine Zeile im Copilot-Verlauf fuer die Anzeige.
struct CopilotAnzeige: Identifiable, Hashable {
    enum Art { case du, satellit, werkzeug }
    let id = UUID()
    let art: Art
    let text: String
}

/// Der Satellit-Copilot — das Gehirn, das die App-Werkzeuge orchestriert.
/// Dreht die Claude-Tool-Use-Schleife: Frage -> Claude ruft Werkzeuge ->
/// echte App-Daten -> Antwort. Die Fusion der 117 Einzelteile zu einem
/// sprechenden Instrument.
///
/// Doktrin bleibt: die Werkzeuge LESEN nur. Schreiben/Speichern passiert
/// weiter ueber die jeweilige View mit Bestaetigung. Der Copilot schlaegt
/// vor, er handelt nicht hinter deinem Ruecken.
@MainActor
@Observable
final class SatellitCopilot {
    private(set) var verlauf: [CopilotAnzeige] = []
    private(set) var denktGerade = false
    private(set) var fehler: String?

    private let werkzeuge: CopilotWerkzeuge
    private let client = CopilotClient()
    private var apiVerlauf: [[String: Any]] = []

    private static let maxSchritte = 6

    private let system = """
    Du bist der Satellit-Copilot von mykilOS mobile - der Feld-Assistent von \
    Johannes (Tischler und Kuechenstudio). Du hast Werkzeuge, um echte lokale \
    Projektdaten zu lesen: Projekte suchen und zusammenfassen, Firefly-Render- \
    Prompts bauen, Sonnenstand berechnen, Kontakte finden. Nutze sie, statt zu \
    raten. Antworte knapp, konkret und auf Deutsch. Wenn Daten fehlen, sag das \
    ehrlich. Du schreibst oder speicherst NICHTS automatisch - du schlaegst vor, \
    der Mensch bestaetigt in der App (Karte->Bestaetigung).
    """

    init(projectStore: ProjectStore, feldFotoStore: FeldFotoStore) {
        self.werkzeuge = CopilotWerkzeuge(projectStore: projectStore, feldFotoStore: feldFotoStore)
    }

    var istVerbunden: Bool { client.istVerbunden }

    func verlaufLeeren() {
        verlauf = []
        apiVerlauf = []
        fehler = nil
    }

    func sende(_ text: String) async {
        let frage = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !frage.isEmpty else { return }
        verlauf.append(CopilotAnzeige(art: .du, text: frage))
        apiVerlauf.append(["role": "user", "content": frage])
        denktGerade = true
        fehler = nil
        defer { denktGerade = false }

        do {
            var schritte = 0
            while schritte < Self.maxSchritte {
                schritte += 1
                let schritt = try await client.schritt(
                    system: system, verlauf: apiVerlauf, werkzeuge: CopilotWerkzeuge.definitionen)
                apiVerlauf.append(["role": "assistant", "content": schritt.assistantContent])

                if let t = schritt.text, !t.isEmpty {
                    verlauf.append(CopilotAnzeige(art: .satellit, text: t))
                }
                guard schritt.brauchtToolLauf else { break }

                var ergebnisBloecke: [[String: Any]] = []
                for aufruf in schritt.toolAufrufe {
                    verlauf.append(CopilotAnzeige(art: .werkzeug, text: werkzeugLabel(aufruf)))
                    let ergebnis = werkzeuge.fuehreAus(name: aufruf.name, eingabe: aufruf.eingabe)
                    ergebnisBloecke.append([
                        "type": "tool_result",
                        "tool_use_id": aufruf.id,
                        "content": ergebnis,
                    ])
                }
                apiVerlauf.append(["role": "user", "content": ergebnisBloecke])
            }
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func werkzeugLabel(_ aufruf: CopilotToolAufruf) -> String {
        switch aufruf.name {
        case "projekte_suchen": return "Projekte durchsucht"
        case "projekt_details": return "Projekt-Akte gelesen"
        case "firefly_prompt": return "Firefly-Prompt gebaut"
        case "sonnenstand": return "Sonnenstand berechnet"
        case "kontakt_finden": return "Kontakt gesucht"
        default: return aufruf.name
        }
    }
}
