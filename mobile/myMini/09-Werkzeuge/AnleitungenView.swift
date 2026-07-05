import QuickLook
import SwiftUI
import UniformTypeIdentifiers

/// Geraete-Anleitungen je Projekt — PDFs einmal importieren (Dateien-App/
/// AirDrop), danach IMMER offline dabei, auch im Keller ohne Netz.
/// Ehrliche Grenze: ein automatischer Abgleich mit dem Projekt-Warenkorb
/// des Schiffs braeuchte einen WorkBasket-Sync, den es auf mobile bewusst
/// noch nicht gibt — bis dahin ist DIES die Heimat der Anleitungen:
/// manuell befuellt, dafuer garantiert verfuegbar. Muster = PlanModelle.
struct GeraeteAnleitung: Identifiable, Codable, Hashable {
    let id: UUID
    let dateiname: String
    let anzeigeName: String
    let projectNumber: String
    let projectTitel: String
    let importiertAm: Date

    init(id: UUID = UUID(), dateiname: String, anzeigeName: String, projectNumber: String, projectTitel: String, importiertAm: Date = Date()) {
        self.id = id
        self.dateiname = dateiname
        self.anzeigeName = anzeigeName
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.importiertAm = importiertAm
    }
}

enum AnleitungenFehler: Error, LocalizedError {
    case writeFailed(String)
    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Anleitung nicht speicherbar: \(detail)"
        }
    }
}

@Observable
final class AnleitungenStore {
    private(set) var anleitungen: [GeraeteAnleitung] = []
    private(set) var loadError: String?

    private let manifestURL: URL
    private let ordnerURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("anleitungen.json")
        self.ordnerURL = documents.appendingPathComponent("Anleitungen", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordnerURL, withIntermediateDirectories: true)
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: manifestURL.path),
              let data = try? Data(contentsOf: manifestURL),
              let geladen = try? JSONDecoder().decode([GeraeteAnleitung].self, from: data) else { return }
        anleitungen = geladen
    }

    func dateiURL(fuer anleitung: GeraeteAnleitung) -> URL {
        ordnerURL.appendingPathComponent(anleitung.dateiname)
    }

    @discardableResult
    func importieren(quelle: URL, projectNumber: String, projectTitel: String) throws -> GeraeteAnleitung {
        let hatZugriff = quelle.startAccessingSecurityScopedResource()
        defer { if hatZugriff { quelle.stopAccessingSecurityScopedResource() } }

        let dateiname = "\(UUID().uuidString).pdf"
        let zielURL = ordnerURL.appendingPathComponent(dateiname)
        do {
            try FileManager.default.copyItem(at: quelle, to: zielURL)
        } catch {
            throw AnleitungenFehler.writeFailed(error.localizedDescription)
        }

        let eintrag = GeraeteAnleitung(
            dateiname: dateiname,
            anzeigeName: quelle.deletingPathExtension().lastPathComponent,
            projectNumber: projectNumber,
            projectTitel: projectTitel
        )
        var next = anleitungen
        next.append(eintrag)
        do {
            let data = try JSONEncoder().encode(next)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: zielURL)
            throw AnleitungenFehler.writeFailed(error.localizedDescription)
        }
        anleitungen = next
        return eintrag
    }

    func remove(_ id: UUID) throws {
        guard let index = anleitungen.firstIndex(where: { $0.id == id }) else { return }
        let dateiname = anleitungen[index].dateiname
        var next = anleitungen
        next.remove(at: index)
        do {
            let data = try JSONEncoder().encode(next)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            throw AnleitungenFehler.writeFailed(error.localizedDescription)
        }
        anleitungen = next
        try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(dateiname))
    }
}

struct AnleitungenView: View {
    let store: ProjectStore

    @State private var anleitungenStore = AnleitungenStore()
    @State private var suche = ""
    @State private var gewaehltesProjekt: Project?
    @State private var zeigeDateiwahl = false
    @State private var vorschauURL: URL?
    @State private var fehler: String?

    private var projekte: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    var body: some View {
        List {
            Section {
                if anleitungenStore.anleitungen.isEmpty {
                    Text("Noch keine Anleitung importiert.")
                        .font(.footnote)
                        .foregroundStyle(MykColor.muted)
                }
                ForEach(anleitungenStore.anleitungen.reversed()) { anleitung in
                    Button {
                        vorschauURL = anleitungenStore.dateiURL(fuer: anleitung)
                    } label: {
                        HStack {
                            Image(systemName: "book.closed.fill").foregroundStyle(MykColor.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(anleitung.anzeigeName).font(.subheadline.weight(.semibold))
                                Text(anleitung.projectTitel).font(.caption).foregroundStyle(MykColor.muted)
                            }
                        }
                    }
                    .foregroundStyle(MykColor.ink)
                    .swipeActions(edge: .trailing) {
                        Button("Loeschen", role: .destructive) {
                            try? anleitungenStore.remove(anleitung.id)
                        }
                    }
                }
            } header: {
                Text("Geraete-Anleitungen")
            } footer: {
                Text("Einmal importiert, immer offline dabei. Automatischer Warenkorb-Abgleich kommt erst mit einem WorkBasket-Sync - bis dahin ehrlich manuell.")
            }

            Section {
                TextField("Projekt suchen...", text: $suche)
                ForEach(projekte.prefix(5)) { project in
                    Button {
                        gewaehltesProjekt = project
                    } label: {
                        HStack {
                            Text(project.title)
                            Spacer()
                            Text(project.projectNumber)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(MykColor.muted)
                            if gewaehltesProjekt?.id == project.id {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.brand)
                            }
                        }
                    }
                    .foregroundStyle(MykColor.ink)
                }
                Button("PDF-Anleitung importieren...") { zeigeDateiwahl = true }
                    .disabled(gewaehltesProjekt == nil)
            } header: {
                Text("Neue Anleitung - Projekt zuerst, nie geraten")
            }

            if let fehler {
                Text(fehler).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Anleitungen")
        .navigationBarTitleDisplayMode(.inline)
        .quickLookPreview($vorschauURL)
        .fileImporter(isPresented: $zeigeDateiwahl, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { ergebnis in
            guard let projekt = gewaehltesProjekt else { return }
            fehler = nil
            do {
                guard let url = try ergebnis.get().first else { return }
                try anleitungenStore.importieren(quelle: url, projectNumber: projekt.projectNumber, projectTitel: projekt.title)
            } catch {
                fehler = Fehlertext.deutsch(error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnleitungenView(store: ProjectStore())
    }
}
