import PencilKit
import QuickLook
import SwiftUI
import UniformTypeIdentifiers

/// Unterschriften-Feld: PencilKit-Canvas, Finger UND Pencil erlaubt.
struct SignaturCanvas: UIViewRepresentable {
    @Binding var zeichnung: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 4)
        canvas.backgroundColor = .white
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing != zeichnung { canvas.drawing = zeichnung }
    }

    func makeCoordinator() -> Koordinator { Koordinator(self) }

    final class Koordinator: NSObject, PKCanvasViewDelegate {
        let eltern: SignaturCanvas
        init(_ eltern: SignaturCanvas) { self.eltern = eltern }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            eltern.zeichnung = canvasView.drawing
        }
    }
}

/// Gefuehrter Signatur-Prozess: Projekt -> Vertrags-PDF -> Name ->
/// Unterschrift -> Bestaetigung -> versiegeltes PDF mit SHA-256-Siegel.
/// Karte->Bestaetigung wie ueberall: nichts wird gespeichert, bevor der
/// letzte Knopf gedrueckt ist. Danach per AirDrop/Mail teilbar.
struct VertragSignierenView: View {
    let store: ProjectStore

    @State private var register = VertragsRegister()
    @State private var suche = ""
    @State private var gewaehltesProjekt: Project?
    @State private var vertragsPDF: URL?
    @State private var zeigeDateiwahl = false
    @State private var unterzeichner = ""
    @State private var zeichnung = PKDrawing()
    @State private var fertigerVertrag: SignierterVertrag?
    @State private var vorschauURL: URL?
    @State private var fehler: String?

    private var projekte: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    var body: some View {
        Form {
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
            } header: {
                Text("Schritt 1: Projekt - nie geraten, immer bestaetigt")
            }

            if gewaehltesProjekt != nil {
                Section {
                    Button(vertragsPDF == nil ? "Vertrags-PDF waehlen..." : "Anderes PDF waehlen...") {
                        zeigeDateiwahl = true
                    }
                    if let vertragsPDF {
                        Label(vertragsPDF.deletingPathExtension().lastPathComponent, systemImage: "doc.fill")
                            .font(.caption)
                    }
                } header: {
                    Text("Schritt 2: Vertrag")
                }
            }

            if vertragsPDF != nil {
                Section {
                    TextField("Vor- und Nachname der Kundin/des Kunden", text: $unterzeichner)
                } header: {
                    Text("Schritt 3: Wer unterschreibt?")
                }

                Section {
                    SignaturCanvas(zeichnung: $zeichnung)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(MykColor.line))
                    Button("Unterschrift loeschen", role: .destructive) { zeichnung = PKDrawing() }
                        .font(.caption)
                } header: {
                    Text("Schritt 4: Unterschrift (Finger oder Pencil)")
                }

                Section {
                    Button("Jetzt versiegeln und ablegen") { versiegeln() }
                        .buttonStyle(.borderedProminent)
                        .tint(MykColor.brand)
                        .disabled(unterzeichner.trimmingCharacters(in: .whitespaces).isEmpty || zeichnung.strokes.isEmpty)
                } header: {
                    Text("Schritt 5: Bestaetigung")
                } footer: {
                    Text("Erzeugt das PDF mit Signatur-Seite und SHA-256-Siegel. Einfache elektronische Signatur mit Beweiskette - keine qualifizierte Signatur.")
                }
            }

            if let fertigerVertrag {
                Section {
                    Label("Versiegelt und im Register abgelegt", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(MykColor.ok)
                    Text(fertigerVertrag.sha256)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(MykColor.muted)
                    ShareLink(item: register.dateiURL(fuer: fertigerVertrag)) {
                        Label("Per AirDrop/Mail teilen", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Fertig - Siegel (SHA-256)")
                }
            }

            if !register.vertraege.isEmpty {
                Section {
                    ForEach(register.vertraege.reversed()) { vertrag in
                        Button {
                            vorschauURL = register.dateiURL(fuer: vertrag)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(vertrag.vertragsName) - \(vertrag.unterzeichner)")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(vertrag.projectTitel) - \(vertrag.unterschriebenAm.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(MykColor.muted)
                            }
                        }
                        .foregroundStyle(MykColor.ink)
                    }
                } header: {
                    Text("Signatur-Register")
                } footer: {
                    Text("Eintraege sind bewusst nicht loeschbar - ein leerbares Register waere keine Beweiskette.")
                }
            }

            if let fehler {
                Text(fehler).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Vertrag signieren")
        .navigationBarTitleDisplayMode(.inline)
        .quickLookPreview($vorschauURL)
        .fileImporter(isPresented: $zeigeDateiwahl, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { ergebnis in
            do {
                guard let url = try ergebnis.get().first else { return }
                // Security-scoped Kopie in tmp, damit das PDF beim Versiegeln lesbar bleibt.
                let hatZugriff = url.startAccessingSecurityScopedResource()
                defer { if hatZugriff { url.stopAccessingSecurityScopedResource() } }
                let ziel = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: ziel)
                try FileManager.default.copyItem(at: url, to: ziel)
                vertragsPDF = ziel
                fertigerVertrag = nil
            } catch {
                fehler = Fehlertext.deutsch(error)
            }
        }
    }

    private func versiegeln() {
        guard let projekt = gewaehltesProjekt, let vertragsPDF else { return }
        fehler = nil
        do {
            let bild = zeichnung.image(from: zeichnung.bounds.insetBy(dx: -10, dy: -10), scale: 2)
            let (daten, hash) = try VertragsSiegel.versiegele(
                originalPDF: vertragsPDF, unterschrift: bild,
                unterzeichner: unterzeichner.trimmingCharacters(in: .whitespaces), projekt: projekt
            )
            fertigerVertrag = try register.ablegen(
                daten: daten,
                vertragsName: vertragsPDF.deletingPathExtension().lastPathComponent,
                projekt: projekt, unterzeichner: unterzeichner, sha256: hash
            )
            zeichnung = PKDrawing()
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack {
        VertragSignierenView(store: ProjectStore())
    }
}
