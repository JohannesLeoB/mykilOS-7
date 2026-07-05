import SwiftUI

/// Foto → grobe Farbtemperatur-Kategorie → Hinweis. Kein Schreiben, keine
/// Postbox, kein Sync — reines Vor-Ort-Werkzeug, Zwilling der
/// `BeleuchtungsCheckView`.
struct FarbtemperaturCheckView: View {
    @State private var bild: UIImage?
    @State private var kategorie: Farbtemperaturkategorie?
    @State private var zeigeKamera = false

    var body: some View {
        VStack(spacing: 18) {
            if let bild {
                Image(uiImage: bild)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxHeight: 320)

                if let kategorie {
                    ergebnis(kategorie)
                }

                Button("Neues Foto") {
                    self.bild = nil
                    self.kategorie = nil
                    zeigeKamera = true
                }
                .buttonStyle(.bordered)
            } else {
                leerZustand
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MykColor.paper)
        .navigationTitle("Farbtemperatur-Check")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $zeigeKamera) {
            KameraAufnahmeView(
                onAufnahme: { foto, _ in
                    bild = foto
                    kategorie = FarbtemperaturAnalyse.analysiere(foto)
                    zeigeKamera = false
                },
                onAbbruch: { zeigeKamera = false }
            )
            .ignoresSafeArea()
        }
    }

    private var leerZustand: some View {
        VStack(spacing: 14) {
            Image(systemName: "paintpalette")
                .font(.system(size: 44))
                .foregroundStyle(MykColor.muted)
            Text("Foto vom Raum oder Material machen — grobe Einschätzung warm/neutral/kühl.")
                .font(.subheadline)
                .foregroundStyle(MykColor.muted)
                .multilineTextAlignment(.center)
            Button("Foto aufnehmen") { zeigeKamera = true }
                .buttonStyle(.borderedProminent)
                .tint(MykColor.brand)
        }
        .padding(.top, 60)
    }

    @ViewBuilder
    private func ergebnis(_ kategorie: Farbtemperaturkategorie) -> some View {
        VStack(spacing: 6) {
            Label(kategorie.rawValue, systemImage: kategorie.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(MykColor.brand)
            Text(kategorie.empfehlung)
                .font(.subheadline)
                .foregroundStyle(MykColor.muted)
                .multilineTextAlignment(.center)
            Text("Grobe Schätzung aus dem Bildfarbverhältnis — kein Kelvin-Messwert, kein kalibrierter Sensor. Für einen exakten Farbabgleich bleibt ein Farbmessgerät nötig.")
                .font(.caption2)
                .foregroundStyle(MykColor.muted)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(MykColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MykColor.line))
    }
}

#Preview {
    NavigationStack {
        FarbtemperaturCheckView()
    }
}
