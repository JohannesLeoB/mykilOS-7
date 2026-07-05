import SwiftUI

/// 3 Sekunden zuhören → grobe Lautstärke-Kategorie. Kein Schreiben, keine
/// Postbox — reines Vor-Ort-Werkzeug, gleicher Aufbau wie Beleuchtungs-Check.
struct RaumakustikCheckView: View {
    @State private var messer = RaumakustikMesser()
    @State private var laeuft = false
    @State private var niveau: Raumklangniveau?
    @State private var fehler: String?

    var body: some View {
        VStack(spacing: 18) {
            if laeuft {
                ProgressView("Höre zu…")
                    .padding(.top, 60)
            } else if let niveau {
                ergebnis(niveau)
                Button("Erneut messen") { messen() }
                    .buttonStyle(.bordered)
            } else {
                leerZustand
            }

            if let fehler {
                Text(fehler).font(.footnote).foregroundStyle(MykColor.crit)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(MykColor.paper)
        .navigationTitle("Raumakustik-Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var leerZustand: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 44))
                .foregroundStyle(MykColor.muted)
            Text("3 Sekunden zuhören — grobe Einschätzung der Umgebungslautstärke, keine Nachhallzeit-Messung.")
                .font(.subheadline)
                .foregroundStyle(MykColor.muted)
                .multilineTextAlignment(.center)
            Button("Messen") { messen() }
                .buttonStyle(.borderedProminent)
                .tint(MykColor.brand)
        }
        .padding(.top, 60)
    }

    @ViewBuilder
    private func ergebnis(_ niveau: Raumklangniveau) -> some View {
        VStack(spacing: 6) {
            Label(niveau.rawValue, systemImage: niveau.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(MykColor.brand)
            Text(niveau.empfehlung)
                .font(.subheadline)
                .foregroundStyle(MykColor.muted)
                .multilineTextAlignment(.center)
            Text("Grobe Lautstärke-Einschätzung aus 3 Sekunden Mikrofon-Pegel — kein kalibriertes Schallpegelmessgerät, keine Nachhallzeit-Berechnung.")
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

    private func messen() {
        fehler = nil
        niveau = nil
        laeuft = true
        Task {
            defer { laeuft = false }
            guard await messer.berechtigungAnfragen() else {
                fehler = RaumakustikFehler.keineBerechtigung.errorDescription
                return
            }
            do {
                niveau = try await messer.messen()
            } catch {
                fehler = Fehlertext.deutsch(error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RaumakustikCheckView()
    }
}
