import PencilKit
import SwiftUI
import UIKit

/// Ein gesetztes Mass auf dem Foto: Position (in Anzeige-Koordinaten des
/// aspektgerecht eingepassten Bildes) + Text (z. B. "2450 mm").
struct MassLabel: Identifiable, Hashable {
    let id = UUID()
    var position: CGPoint
    var text: String
}

/// Transparente PencilKit-Flaeche ueber dem Foto — Finger UND Apple Pencil
/// (auf dem iPad wird genau daraus der Aufmass-Modus mit Stift). Rote Linien,
/// damit sie sich von jeder Baustelle abheben.
struct BemassungsZeichenflaeche: UIViewRepresentable {
    @Binding var zeichnung: PKDrawing
    let aktiv: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .systemRed, width: 3)
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing != zeichnung { canvas.drawing = zeichnung }
        canvas.isUserInteractionEnabled = aktiv
    }

    func makeCoordinator() -> Koordinator { Koordinator(self) }

    final class Koordinator: NSObject, PKCanvasViewDelegate {
        let eltern: BemassungsZeichenflaeche
        init(_ eltern: BemassungsZeichenflaeche) { self.eltern = eltern }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            eltern.zeichnung = canvasView.drawing
        }
    }
}

/// Brennt Zeichnung + Mass-Labels in voller Fotoaufloesung ins Bild ein.
/// Anzeige-Koordinaten werden ueber den Aspekt-Fit-Faktor hochskaliert.
enum BemassungsRenderer {
    static func einbrennen(
        bild: UIImage,
        zeichnung: PKDrawing,
        labels: [MassLabel],
        anzeigeGroesse: CGSize
    ) -> UIImage {
        guard anzeigeGroesse.width > 0 else { return bild }
        let faktor = bild.size.width / anzeigeGroesse.width
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: bild.size, format: format)
        return renderer.image { _ in
            bild.draw(in: CGRect(origin: .zero, size: bild.size))

            let linien = zeichnung.image(
                from: CGRect(origin: .zero, size: anzeigeGroesse), scale: faktor
            )
            linien.draw(in: CGRect(origin: .zero, size: bild.size))

            let schrift = UIFont.boldSystemFont(ofSize: 15 * faktor)
            for label in labels {
                let text = label.text as NSString
                let attribute: [NSAttributedString.Key: Any] = [
                    .font: schrift, .foregroundColor: UIColor.systemRed
                ]
                let groesse = text.size(withAttributes: attribute)
                let mitte = CGPoint(x: label.position.x * faktor, y: label.position.y * faktor)
                let rahmen = CGRect(
                    x: mitte.x - groesse.width / 2 - 4 * faktor,
                    y: mitte.y - groesse.height / 2 - 2 * faktor,
                    width: groesse.width + 8 * faktor,
                    height: groesse.height + 4 * faktor
                )
                let pfad = UIBezierPath(roundedRect: rahmen, cornerRadius: 3 * faktor)
                UIColor.white.withAlphaComponent(0.85).setFill()
                pfad.fill()
                text.draw(
                    at: CGPoint(x: mitte.x - groesse.width / 2, y: mitte.y - groesse.height / 2),
                    withAttributes: attribute
                )
            }
        }
    }
}

/// Foto-Bemassung — der Stift-Teil von Johannes' iPad-Aufmass-Vision, laeuft
/// heute schon auf dem iPhone mit dem Finger: Foto aufnehmen, Masslinien
/// zeichnen, Masszahlen setzen, Ergebnis als Feld-Foto einbrennen.
/// Ehrliche Grenze: die Zahlen kommen JETZT aus Laser-Ablesen + Eintippen.
/// Live-Uebernahme direkt aus dem Bluetooth-Laser folgt, sobald ein echtes
/// Geraet gekoppelt ist (Adapter-Fundament liegt bereit, Protokoll-
/// Verifikation braucht Hardware).
struct FotoBemassungView: View {
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    /// App-weiter Laser-Empfaenger — gekoppelt wird in "Verbindungen",
    /// gemessen hier. Off-by-default; ohne aktiven Toggle bleibt er stumm.
    private let laser = BluetoothLaserScanner.shared

    private enum Modus { case zeichnen, beschriften }

    @State private var suche = ""
    @State private var gewaehltesProjekt: Project?
    @State private var zeigeKamera = false
    @State private var bild: UIImage?
    @State private var zeichnung = PKDrawing()
    @State private var labels: [MassLabel] = []
    @State private var modus: Modus = .zeichnen
    @State private var massText = ""
    @State private var anzeigeGroesse: CGSize = .zero
    @State private var gespeichert = false
    @State private var fehler: String?

    private var projekte: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    var body: some View {
        Group {
            if let bild {
                editor(bild: bild)
            } else {
                projektwahl
            }
        }
        .navigationTitle("Foto-Bemassung")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $zeigeKamera) {
            KameraAufnahmeView(
                onAufnahme: { neuesBild, _ in
                    bild = neuesBild
                    zeichnung = PKDrawing()
                    labels = []
                    gespeichert = false
                    zeigeKamera = false
                },
                onAbbruch: { zeigeKamera = false }
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Schritt 1: Projekt + Foto

    private var projektwahl: some View {
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
            Section {
                Button {
                    zeigeKamera = true
                } label: {
                    Label("Foto der Raumsituation aufnehmen", systemImage: "camera.fill")
                }
                .disabled(gewaehltesProjekt == nil)
            } header: {
                Text("Schritt 2: Foto")
            } footer: {
                Text("Danach: Masslinien mit Stift oder Finger zeichnen, Masszahlen setzen, Ergebnis als Feld-Foto einbrennen. Auf dem iPad wird daraus der Aufmass-Modus mit Apple Pencil.")
            }
        }
    }

    // MARK: - Schritt 2: Editor

    private func editor(bild: UIImage) -> some View {
        VStack(spacing: 8) {
            Picker("Modus", selection: $modus) {
                Text("Linien zeichnen").tag(Modus.zeichnen)
                Text("Mass setzen").tag(Modus.beschriften)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)

            if modus == .beschriften {
                HStack {
                    TextField("Mass eintippen (z. B. 2450 mm), dann aufs Foto tippen", text: $massText)
                        .textFieldStyle(.roundedBorder)
                    // Live-Funk vom gekoppelten Leica DISTO: Messwert mit
                    // einem Tipp uebernehmen statt abtippen. Erscheint nur,
                    // wenn wirklich ein Wert angekommen ist.
                    if let millimeter = laser.letzterMesswertMM {
                        Button("\(millimeter) mm") {
                            massText = "\(millimeter) mm"
                        }
                        .buttonStyle(.bordered)
                        .tint(MykColor.brand)
                        .font(.footnote.weight(.semibold))
                        .accessibilityLabel("Laser-Messwert \(millimeter) Millimeter uebernehmen")
                    }
                }
                .padding(.horizontal, 12)
            }

            GeometryReader { geo in
                let groesse = eingepasst(bild.size, in: geo.size)
                ZStack {
                    Image(uiImage: bild)
                        .resizable()
                        .scaledToFit()
                    BemassungsZeichenflaeche(zeichnung: $zeichnung, aktiv: modus == .zeichnen)
                    ForEach(labels) { label in
                        Text(label.text)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .position(label.position)
                            .onTapGesture {
                                if modus == .beschriften {
                                    labels.removeAll { $0.id == label.id }
                                }
                            }
                    }
                }
                .frame(width: groesse.width, height: groesse.height)
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { ort in
                    guard modus == .beschriften else { return }
                    let text = massText.trimmingCharacters(in: .whitespaces)
                    guard !text.isEmpty else { return }
                    labels.append(MassLabel(position: ort, text: text))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { anzeigeGroesse = groesse }
                .onChange(of: geo.size) { anzeigeGroesse = eingepasst(bild.size, in: geo.size) }
            }

            if let fehler {
                Text(fehler).font(.footnote).foregroundStyle(MykColor.crit)
            }
            if gespeichert {
                Label("Als Feld-Foto gespeichert", systemImage: "checkmark.seal.fill")
                    .font(.footnote)
                    .foregroundStyle(MykColor.ok)
            }

            HStack(spacing: 10) {
                Button("Verwerfen", role: .destructive) {
                    self.bild = nil
                    zeichnung = PKDrawing()
                    labels = []
                    gespeichert = false
                }
                .buttonStyle(.bordered)
                Button("Neu zeichnen") {
                    zeichnung = PKDrawing()
                    labels = []
                }
                .buttonStyle(.bordered)
                Button("Einbrennen + speichern") { speichern(bild: bild) }
                    .buttonStyle(.borderedProminent)
                    .tint(MykColor.brand)
                    .disabled(gespeichert || (zeichnung.strokes.isEmpty && labels.isEmpty))
            }
            .font(.footnote.weight(.semibold))
            .padding(.bottom, 10)
        }
        .background(MykColor.paper)
    }

    /// Aspekt-Fit: so rechnet die Anzeige, so rechnet spaeter der Renderer —
    /// dieselbe Groesse an beiden Stellen, sonst verrutschen die Masse.
    private func eingepasst(_ bildGroesse: CGSize, in container: CGSize) -> CGSize {
        guard bildGroesse.width > 0, bildGroesse.height > 0 else { return container }
        let skala = min(container.width / bildGroesse.width, container.height / bildGroesse.height)
        return CGSize(width: bildGroesse.width * skala, height: bildGroesse.height * skala)
    }

    private func speichern(bild: UIImage) {
        guard let projekt = gewaehltesProjekt else { return }
        fehler = nil
        let fertig = BemassungsRenderer.einbrennen(
            bild: bild, zeichnung: zeichnung, labels: labels, anzeigeGroesse: anzeigeGroesse
        )
        do {
            try feldFotoStore.aufnehmen(
                bild: fertig,
                projectNumber: projekt.projectNumber,
                projectTitel: projekt.title,
                kanonZiel: .bestand,
                aufgenommenAm: Date(),
                breitengrad: nil,
                laengengrad: nil
            )
            gespeichert = true
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack {
        FotoBemassungView(store: ProjectStore(), feldFotoStore: FeldFotoStore())
    }
}
