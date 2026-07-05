import RoomPlan
import SwiftUI
import UIKit

/// RoomPlan-Aufmaß (#5): Projekt wählen, Raum scannen (Apples eigene
/// Scan-UI), Ergebnis als USDZ sichern. Braucht ein LiDAR-Gerät — auf
/// anderen Geräten ehrlicher Fallback-Zustand statt Absturz.
struct RoomPlanCaptureScreen: View {
    let store: ProjectStore
    let roomPlanStore: RoomPlanStore

    @State private var suche = ""
    @State private var gewaehltesProjekt: Project?
    @State private var zeigeScan = false
    @State private var stoppAnfrage = false
    @State private var fertigesErgebnis: RoomPlanErgebnis?
    @State private var fehler: String?
    @State private var gespeichert = false
    @State private var exportDatei: ExportDatei?

    private var projekte: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    var body: some View {
        Group {
            if RoomCaptureSession.isSupported {
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

                    if let gewaehltesProjekt {
                        Section {
                            Button("Raum scannen") { zeigeScan = true }
                                .buttonStyle(.borderedProminent)
                                .tint(MykColor.brand)
                        } footer: {
                            Text("Scan für \(gewaehltesProjekt.title). Apples eigene geführte Scan-Ansicht öffnet sich.")
                        }
                    }

                    if let fertigesErgebnis, let gewaehltesProjekt {
                        Section("Scan fertig — 3D") {
                            if gespeichert {
                                Label("Gespeichert", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(MykColor.ok)
                            } else {
                                Button("Für \(gewaehltesProjekt.title) speichern") {
                                    speichern(fertigesErgebnis.usdzURL, projekt: gewaehltesProjekt)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(MykColor.brand)
                            }
                        }

                        Section {
                            Button("Als PDF-Grundriss teilen") { pdfExportieren(fertigesErgebnis.geometrie) }
                            Button("Als DXF exportieren (VectorWorks-Unterlage)") { dxfExportieren(fertigesErgebnis.geometrie) }
                        } header: {
                            Text("2D-Zeichnung")
                        } footer: {
                            Text("Referenz-Grundriss aus dem Scan — Maße auf RoomPlan-Genauigkeit (~cm), kein Ersatz für ein Laser-Aufmaß.")
                        }
                    }

                    if let fehler {
                        Text(fehler).foregroundStyle(MykColor.crit)
                    }
                }
            } else {
                ContentUnavailableView(
                    "RoomPlan nicht unterstützt",
                    systemImage: "arkit",
                    description: Text("RoomPlan braucht ein Gerät mit LiDAR-Scanner (z. B. iPhone Pro).")
                )
            }
        }
        .navigationTitle("RoomPlan-Aufmaß")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $zeigeScan) {
            ZStack(alignment: .bottom) {
                RoomPlanCaptureBridge(stoppAnfrage: $stoppAnfrage) { ergebnis in
                    fertigesErgebnis = ergebnis
                    gespeichert = false
                    if ergebnis == nil {
                        fehler = "Scan fehlgeschlagen — bitte erneut versuchen."
                    }
                    zeigeScan = false
                }
                .ignoresSafeArea()

                Button("Fertig") { stoppAnfrage = true }
                    .buttonStyle(.borderedProminent)
                    .tint(MykColor.brand)
                    .padding(.bottom, 40)
            }
        }
        .sheet(item: $exportDatei) { wrapper in
            TeilenAnsicht(activityItems: [wrapper.url])
        }
    }

    private func speichern(_ url: URL, projekt: Project) {
        do {
            try roomPlanStore.aufnehmen(usdzQuelle: url, projectNumber: projekt.projectNumber, projectTitel: projekt.title)
            gespeichert = true
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func pdfExportieren(_ geometrie: RaumGeometrie) {
        do {
            let url = try GrundrissPDFRenderer.erstellePDF(geometrie: geometrie, titel: gewaehltesProjekt?.title ?? "Grundriss")
            exportDatei = ExportDatei(url: url)
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func dxfExportieren(_ geometrie: RaumGeometrie) {
        do {
            let url = try GrundrissDXFExporter.erstelleDXF(geometrie: geometrie)
            exportDatei = ExportDatei(url: url)
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack {
        RoomPlanCaptureScreen(store: ProjectStore(), roomPlanStore: RoomPlanStore())
    }
}
