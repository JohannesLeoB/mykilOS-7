import SwiftUI

/// Abnahmeprotokoll per Diktat (#11) — Freisprech-Mängelaufnahme mit
/// nummeriertem Protokoll + optionaler Fotoverknüpfung je Eintrag. Diktieren
/// nutzt dieselbe `SprachaufnahmeView` wie die Fang-Karte (kein Doppelbau),
/// Text bleibt nach dem Diktat editierbar/tippbar — gleiche "Sprich oder
/// tippe"-Haltung. Projekt wird nie geraten, immer explizit gewählt.
struct AbnahmeprotokollView: View {
    let store: ProjectStore

    @State private var protokollStore = AbnahmeprotokollStore()
    @State private var suche = ""
    @State private var gewaehltesProjekt: Project?
    @State private var neuerText = ""
    @State private var neuesFoto: UIImage?
    @State private var zeigeDiktat = false
    @State private var zeigeKamera = false
    @State private var fehler: String?
    @State private var exportDatei: ExportDatei?

    private var projekte: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    private var eintraegeFuerProjekt: [MangelEintrag] {
        guard let gewaehltesProjekt else { return [] }
        return protokollStore.eintraege
            .filter { $0.projectNumber == gewaehltesProjekt.projectNumber }
            .sorted { $0.erfasstAm < $1.erfasstAm }
    }

    var body: some View {
        Form {
            Section("Projekt — nie geraten, immer bestätigt") {
                TextField("Projekt suchen…", text: $suche)
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
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MykColor.brand)
                            }
                        }
                    }
                    .foregroundStyle(MykColor.ink)
                }
            }

            if gewaehltesProjekt != nil {
                Section("Neuer Mangel") {
                    TextField("Sprich oder tippe den Mangel…", text: $neuerText, axis: .vertical)
                        .lineLimit(2...4)

                    HStack(spacing: 8) {
                        Button {
                            zeigeDiktat = true
                        } label: {
                            Label("Diktieren", systemImage: "mic.fill")
                        }
                        Button {
                            zeigeKamera = true
                        } label: {
                            Label("Foto anhängen", systemImage: "camera.fill")
                        }
                    }
                    .font(.footnote.weight(.semibold))

                    if let neuesFoto {
                        HStack {
                            Image(uiImage: neuesFoto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Button("Entfernen", role: .destructive) { self.neuesFoto = nil }
                                .font(.caption)
                        }
                    }

                    Button("Mangel hinzufügen") { hinzufuegen() }
                        .disabled(neuerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let fehler {
                    Text(fehler).foregroundStyle(MykColor.crit)
                }

                Section("Protokoll") {
                    if eintraegeFuerProjekt.isEmpty {
                        Text("Noch kein Mangel erfasst.")
                            .font(.footnote)
                            .foregroundStyle(MykColor.muted)
                    } else {
                        ForEach(Array(eintraegeFuerProjekt.enumerated()), id: \.element.id) { index, eintrag in
                            row(nummer: index + 1, eintrag: eintrag)
                                .swipeActions(edge: .trailing) {
                                    Button("Löschen", role: .destructive) {
                                        try? protokollStore.remove(eintrag.id)
                                    }
                                }
                        }
                        Button {
                            pdfTeilen()
                        } label: {
                            Label("Als PDF teilen", systemImage: "doc.richtext")
                        }
                    }
                }
            }
        }
        .navigationTitle("Abnahmeprotokoll")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $zeigeDiktat) {
            SprachaufnahmeView(
                onFertig: { text in
                    neuerText = text
                    zeigeDiktat = false
                },
                onAbbruch: { zeigeDiktat = false }
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $zeigeKamera) {
            KameraAufnahmeView(
                onAufnahme: { bild, _ in
                    neuesFoto = bild
                    zeigeKamera = false
                },
                onAbbruch: { zeigeKamera = false }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $exportDatei) { wrapper in
            TeilenAnsicht(activityItems: [wrapper.url])
        }
    }

    private func pdfTeilen() {
        guard let projekt = gewaehltesProjekt else { return }
        do {
            let url = try AbnahmeprotokollPDFRenderer.erstellePDF(
                projektTitel: projekt.title,
                projectNumber: projekt.projectNumber,
                eintraege: eintraegeFuerProjekt,
                bildURL: { protokollStore.bildURL(fuer: $0) }
            )
            exportDatei = ExportDatei(url: url)
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func hinzufuegen() {
        guard let projekt = gewaehltesProjekt else { return }
        let text = neuerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            try protokollStore.hinzufuegen(
                projectNumber: projekt.projectNumber,
                projectTitel: projekt.title,
                text: text,
                foto: neuesFoto
            )
            neuerText = ""
            neuesFoto = nil
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    @ViewBuilder
    private func row(nummer: Int, eintrag: MangelEintrag) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Text("\(nummer)")
                .font(.system(.footnote, design: .monospaced).weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(MykColor.brand)
                .clipShape(Circle())
            if let bildURL = protokollStore.bildURL(fuer: eintrag),
               let bild = UIImage(contentsOfFile: bildURL.path) {
                Image(uiImage: bild)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(eintrag.text).font(.subheadline)
                Text(eintrag.erfasstAm, style: .relative)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(MykColor.muted)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        AbnahmeprotokollView(store: ProjectStore())
    }
}
