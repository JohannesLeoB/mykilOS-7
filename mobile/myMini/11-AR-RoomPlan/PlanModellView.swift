import QuickLook
import SwiftUI
import UniformTypeIdentifiers

/// Planmodelle (#38, Stufe 1): USDZ aus VectorWorks importieren, Projekt
/// zuordnen, im echten Raum ansehen. Die AR-Darstellung übernimmt komplett
/// Apples AR Quick Look (`.quickLookPreview`) — Modell auf den Boden
/// stellen, drehen, skalieren, alles eingebaute iOS-Gesten. Bewusst KEINE
/// automatische Raum-Ausrichtung (Stufe 2, eigenes Vorhaben — automatische
/// CAD-zu-Scan-Registrierung ist ein Forschungsproblem, das wir nicht
/// nebenbei lösen).
struct PlanModellView: View {
    let store: ProjectStore

    @State private var modellStore = PlanModellStore()
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
                if modellStore.modelle.isEmpty {
                    Text("Noch kein Modell importiert.")
                        .font(.footnote)
                        .foregroundStyle(MykColor.muted)
                } else {
                    ForEach(modellStore.modelle.reversed()) { modell in
                        Button {
                            vorschauURL = modellStore.dateiURL(fuer: modell)
                        } label: {
                            HStack {
                                Image(systemName: "cube.fill").foregroundStyle(MykColor.brand)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(modell.anzeigeName).font(.subheadline.weight(.semibold))
                                    Text("\(modell.projectTitel) · \(modell.importiertAm.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(MykColor.muted)
                                }
                            }
                        }
                        .foregroundStyle(MykColor.ink)
                        .swipeActions(edge: .trailing) {
                            Button("Löschen", role: .destructive) {
                                try? modellStore.remove(modell.id)
                            }
                        }
                    }
                }
            } header: {
                Text("Planmodelle")
            } footer: {
                Text("Antippen zeigt das Modell in AR im echten Raum — frei platzierbar, keine automatische Ausrichtung. Der Weg dorthin: VectorWorks → 3D-Export → Apples Reality Converter → USDZ → AirDrop aufs iPhone.")
            }

            Section("Neues Modell — Projekt zuerst, nie geraten") {
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
                Button("USDZ-Datei wählen…") { zeigeDateiwahl = true }
                    .disabled(gewaehltesProjekt == nil)
            }

            if let fehler {
                Text(fehler).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Planmodelle · AR")
        .navigationBarTitleDisplayMode(.inline)
        .quickLookPreview($vorschauURL)
        .fileImporter(
            isPresented: $zeigeDateiwahl,
            allowedContentTypes: [.usdz],
            allowsMultipleSelection: false
        ) { ergebnis in
            importiere(ergebnis)
        }
    }

    private func importiere(_ ergebnis: Result<[URL], Error>) {
        guard let projekt = gewaehltesProjekt else { return }
        fehler = nil
        do {
            guard let url = try ergebnis.get().first else { return }
            try modellStore.importieren(quelle: url, projectNumber: projekt.projectNumber, projectTitel: projekt.title)
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack {
        PlanModellView(store: ProjectStore())
    }
}
