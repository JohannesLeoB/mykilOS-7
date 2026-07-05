import SwiftUI

/// Die eigentliche "Sprich"-Hälfte von "Sprich oder tippe einen Moment…" —
/// live Transkript, Fertig übergibt den Text an dieselbe Fang→Versteh-
/// Pipeline wie getippter Text.
struct SprachaufnahmeView: View {
    let onFertig: (String) -> Void
    let onAbbruch: () -> Void

    @State private var service = SpracheZuTextService()
    @State private var text = ""
    @State private var fehler: String?
    @State private var laeuft = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundStyle(MykColor.brand)
                .symbolEffect(.variableColor.iterative, isActive: laeuft)

            Text(text.isEmpty ? "Sprich jetzt…" : text)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .foregroundStyle(text.isEmpty ? MykColor.muted : MykColor.ink)

            if let fehler {
                Text(fehler).font(.footnote).foregroundStyle(MykColor.crit)
            }

            HStack(spacing: 16) {
                Button("Abbrechen", role: .cancel) {
                    service.stoppen()
                    onAbbruch()
                }
                .buttonStyle(.bordered)

                Button("Fertig") {
                    let ergebnis = service.stoppen()
                    onFertig(ergebnis)
                }
                .buttonStyle(.borderedProminent)
                .tint(MykColor.brand)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MykColor.paper)
        .task {
            let ok = await service.berechtigungenAnfragen()
            guard ok else {
                fehler = SpracheFehler.keineBerechtigung.errorDescription
                return
            }
            do {
                laeuft = true
                try service.starten { neuerText in
                    text = neuerText
                }
            } catch {
                fehler = Fehlertext.deutsch(error)
                laeuft = false
            }
        }
    }
}

#Preview {
    SprachaufnahmeView(onFertig: { _ in }, onAbbruch: {})
}
