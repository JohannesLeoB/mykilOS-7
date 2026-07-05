import SwiftUI

/// Foto → Helligkeitsanalyse → Empfehlung. Kein Schreiben, keine Postbox,
/// kein Sync — ein reines Werkzeug für den Moment vor Ort. Nutzt dieselbe
/// Kamera-Bridge wie Feld-Foto/Visitenkarte (`KameraAufnahmeView`).
struct BeleuchtungsCheckView: View {
    @State private var bild: UIImage?
    @State private var niveau: Beleuchtungsniveau?
    @State private var zeigeKamera = false

    var body: some View {
        VStack(spacing: 18) {
            if let bild {
                Image(uiImage: bild)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxHeight: 320)

                if let niveau {
                    ergebnis(niveau)
                }

                Button("Neues Foto") {
                    self.bild = nil
                    self.niveau = nil
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
        .navigationTitle("Beleuchtungs-Check")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $zeigeKamera) {
            KameraAufnahmeView(
                onAufnahme: { foto, _ in
                    bild = foto
                    niveau = HelligkeitsAnalyse.analysiere(foto)
                    zeigeKamera = false
                },
                onAbbruch: { zeigeKamera = false }
            )
            .ignoresSafeArea()
        }
    }

    private var leerZustand: some View {
        VStack(spacing: 14) {
            Image(systemName: "sun.max")
                .font(.system(size: 44))
                .foregroundStyle(MykColor.muted)
            Text("Foto vom Arbeitsplatz oder Raum machen — wir schätzen die Helligkeit ein.")
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
    private func ergebnis(_ niveau: Beleuchtungsniveau) -> some View {
        VStack(spacing: 6) {
            Label(niveau.rawValue, systemImage: niveau.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(MykColor.brand)
            Text(niveau.empfehlung)
                .font(.subheadline)
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
        BeleuchtungsCheckView()
    }
}
