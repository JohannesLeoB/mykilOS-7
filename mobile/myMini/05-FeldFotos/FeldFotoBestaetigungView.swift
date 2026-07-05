import SwiftUI
import CoreLocation

/// Karte→Bestätigung für ★3 — mirrort das Fang-Karte-Muster von ★1. Nie
/// raten, welches Projekt gemeint ist: der Mensch wählt es explizit, der
/// „Ja, ab in die Drive damit"-Knopf bleibt gesperrt, bis Projekt UND
/// Kanon-Ziel feststehen.
struct FeldFotoBestaetigungView: View {
    let bild: UIImage
    let aufgenommenAm: Date
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore
    let onFertig: () -> Void

    @State private var suche = ""
    @State private var gewaehltesProjekt: Project?
    @State private var kanonZiel: KanonZiel = .bestand
    @State private var foerderrelevant = false
    @State private var fehler: String?
    @State private var ortsSensor = EinmaligerOrtsSensor()
    @State private var breitengrad: Double?
    @State private var laengengrad: Double?

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
                    Text("Aufgenommen \(aufgenommenAm.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(MykColor.muted)
                    if let breitengrad, let laengengrad {
                        Text("Standort: \(breitengrad, specifier: "%.5f"), \(laengengrad, specifier: "%.5f")")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(MykColor.muted)
                    }
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

                Section("Kanon-Zielschublade") {
                    Picker("Ziel", selection: $kanonZiel) {
                        ForEach(KanonZiel.allCases) { ziel in
                            Text("\(ziel.titel) · \(ziel.ordner)").tag(ziel)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Toggle("Förderrelevant (KfW/BAFA-Beweis)", isOn: $foerderrelevant)
                } footer: {
                    Text("Landet im Förderungs-Beweispaket dieses Projekts — nachträglich in der Feld-Foto-Liste änderbar.")
                }

                if let fehler {
                    Text(fehler).foregroundStyle(MykColor.crit)
                }
            }
            .navigationTitle("Feld-Foto verräumen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Verwerfen", role: .destructive) { onFertig() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ja, ab in die Drive damit") { bestaetigen() }
                        .disabled(gewaehltesProjekt == nil)
                }
            }
        }
        .task {
            if let ort = await ortsSensor.hole() {
                breitengrad = ort.latitude
                laengengrad = ort.longitude
            }
        }
    }

    private func bestaetigen() {
        guard let projekt = gewaehltesProjekt else { return }
        do {
            try feldFotoStore.aufnehmen(
                bild: bild,
                projectNumber: projekt.projectNumber,
                projectTitel: projekt.title,
                kanonZiel: kanonZiel,
                aufgenommenAm: aufgenommenAm,
                breitengrad: breitengrad,
                laengengrad: laengengrad,
                foerderrelevant: foerderrelevant
            )
            onFertig()
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}
