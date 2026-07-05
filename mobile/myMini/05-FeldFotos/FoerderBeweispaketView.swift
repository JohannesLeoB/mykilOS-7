import SwiftUI

/// Förderungs-Beweispaket (#52), erreichbarer Teil ohne AR: förderrelevant
/// markierte Feld-Fotos eines Projekts, datiert — als Roh-Bündel ("Fotos
/// teilen") ODER als einreichfertiger PDF-Bericht (eine Seite je datiertem
/// Beleg). Der ARWorldMap-Rückkehr-Teil derselben Idee bleibt bewusst
/// zurückgestellt (siehe `docs/19_BACKLOG_BAUSTAND.md`).
struct FoerderBeweispaketView: View {
    let feldFotoStore: FeldFotoStore
    let store: ProjectStore

    @State private var gewaehlteProjectNumber: String?
    @State private var exportDatei: ExportDatei?
    @State private var fehler: String?

    private var projekteMitFoerderfotos: [(projectNumber: String, projectTitel: String, anzahl: Int)] {
        let gruppiert = Dictionary(grouping: feldFotoStore.fotos.filter(\.foerderrelevant)) { $0.projectNumber }
        return gruppiert.map { (nummer, fotos) in
            (projectNumber: nummer, projectTitel: fotos.first?.projectTitel ?? nummer, anzahl: fotos.count)
        }
        .sorted { $0.projectNumber > $1.projectNumber }
    }

    private var fotosFuerGewaehltesProjekt: [FeldFoto] {
        guard let gewaehlteProjectNumber else { return [] }
        return feldFotoStore.fotos
            .filter { $0.foerderrelevant && $0.projectNumber == gewaehlteProjectNumber }
            .sorted { $0.aufgenommenAm < $1.aufgenommenAm }
    }

    var body: some View {
        List {
            if projekteMitFoerderfotos.isEmpty {
                ContentUnavailableView(
                    "Noch keine förderrelevanten Fotos",
                    systemImage: "rosette",
                    description: Text("Feld-Foto in der Liste per Kontextmenü markieren.")
                )
            } else {
                ForEach(projekteMitFoerderfotos, id: \.projectNumber) { eintrag in
                    Button {
                        gewaehlteProjectNumber = eintrag.projectNumber
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(eintrag.projectTitel).font(.subheadline.weight(.semibold))
                                Text("\(eintrag.anzahl) förderrelevante Fotos")
                                    .font(.caption)
                                    .foregroundStyle(MykColor.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(MykColor.muted)
                        }
                    }
                    .foregroundStyle(MykColor.ink)
                }
            }
        }
        .navigationTitle("Förderungs-Beweispakete")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { gewaehlteProjectNumber.map { ProjektAuswahl(projectNumber: $0) } },
            set: { gewaehlteProjectNumber = $0?.projectNumber }
        )) { _ in
            NavigationStack {
                beweispaket
            }
        }
    }

    @ViewBuilder
    private var beweispaket: some View {
        let fotos = fotosFuerGewaehltesProjekt
        List {
            Section {
                ForEach(fotos) { foto in
                    HStack(spacing: 11) {
                        if let bild = UIImage(contentsOfFile: feldFotoStore.bildURL(fuer: foto).path) {
                            Image(uiImage: bild)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(foto.kanonZiel.titel).font(.subheadline)
                            Text(foto.aufgenommenAm.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(MykColor.muted)
                        }
                    }
                }
            } footer: {
                Text("Datiert, chronologisch — echte Vorher/Nachher-Belege aus EXIF-Zeitstempel.")
            }

            Section {
                Button {
                    pdfBerichtTeilen(fotos)
                } label: {
                    Label("Als PDF-Bericht teilen", systemImage: "doc.richtext")
                }
                .disabled(fotos.isEmpty)
            } footer: {
                Text("Einreichfertige Fassung: Deckblatt + eine datierte Seite je Beleg.")
            }

            if let fehler {
                Text(fehler).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle(fotos.first?.projectTitel ?? "Beweispaket")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fertig") { gewaehlteProjectNumber = nil }
            }
            ToolbarItem(placement: .confirmationAction) {
                ShareLink(items: fotos.map { feldFotoStore.bildURL(fuer: $0) }) {
                    Label("Bündel teilen", systemImage: "square.and.arrow.up")
                }
                .disabled(fotos.isEmpty)
            }
        }
        .sheet(item: $exportDatei) { wrapper in
            TeilenAnsicht(activityItems: [wrapper.url])
        }
    }

    private func pdfBerichtTeilen(_ fotos: [FeldFoto]) {
        guard let erstesFoto = fotos.first else { return }
        do {
            let url = try FoerderBeweispaketPDFRenderer.erstellePDF(
                projektTitel: erstesFoto.projectTitel,
                projectNumber: erstesFoto.projectNumber,
                fotos: fotos,
                bildURL: { feldFotoStore.bildURL(fuer: $0) }
            )
            exportDatei = ExportDatei(url: url)
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

private struct ProjektAuswahl: Identifiable {
    let projectNumber: String
    var id: String { projectNumber }
}

#Preview {
    NavigationStack {
        FoerderBeweispaketView(feldFotoStore: FeldFotoStore(), store: ProjectStore())
    }
}
