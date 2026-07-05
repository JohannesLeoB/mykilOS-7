import SwiftUI

/// Karte→Bestätigung fürs Lieferschein-Fangen. OCR liefert nur Vorschläge —
/// jedes Feld bleibt editierbar, das Projekt wird nie geraten, immer explizit
/// gewählt (gleiches Muster wie `FeldFotoBestaetigungView`).
struct LieferscheinBestaetigungView: View {
    let bild: UIImage
    let store: ProjectStore
    let wareneingangStore: WareneingangsLogStore
    let onFertig: () -> Void

    @State private var trackingNummer = ""
    @State private var absender = ""
    @State private var laedt = true
    @State private var fehler: String?
    @State private var suche = ""
    @State private var gewaehltesProjekt: Project?

    private var projekte: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image(uiImage: bild)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Section {
                    TextField("Tracking-Nummer", text: $trackingNummer)
                        .textInputAutocapitalization(.characters)
                    TextField("Absender", text: $absender)
                } header: {
                    Text("Erkannt — bitte kurz prüfen")
                } footer: {
                    Text("Texterkennung ist ein Vorschlag, kein Fakt — bitte gegenlesen.")
                }

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

                if let fehler {
                    Text(fehler).foregroundStyle(MykColor.crit)
                }
            }
            .navigationTitle("Lieferschein")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Verwerfen", role: .destructive) { onFertig() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Als Wareneingang loggen") { loggen() }
                        .disabled(gewaehltesProjekt == nil)
                }
            }
            .overlay {
                if laedt {
                    ProgressView("Text wird erkannt…")
                        .padding(16)
                        .background(MykColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .task {
            let erkennung = await LieferscheinOCR.erkenne(in: bild)
            trackingNummer = erkennung.trackingNummer
            absender = erkennung.absender
            laedt = false
        }
    }

    private func loggen() {
        guard let projekt = gewaehltesProjekt else { return }
        do {
            try wareneingangStore.append(
                WareneingangsEreignis(
                    projectNumber: projekt.projectNumber,
                    projectTitel: projekt.title,
                    trackingNummer: trackingNummer,
                    absender: absender
                )
            )
            onFertig()
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    LieferscheinBestaetigungView(
        bild: UIImage(systemName: "shippingbox") ?? UIImage(),
        store: ProjectStore(),
        wareneingangStore: WareneingangsLogStore(),
        onFertig: {}
    )
}
