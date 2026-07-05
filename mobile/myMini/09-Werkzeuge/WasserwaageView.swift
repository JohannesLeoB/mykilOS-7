import SwiftUI

/// Gyroskop-Wasserwaage — Telefon flach auf die Fläche legen, Punkt wandert
/// zur Mitte, wenn eben. ±0,5° gilt als "eben" (grüne Rückmeldung).
struct WasserwaageView: View {
    @State private var sensor = WasserwaageSensor()

    private let toleranzGrad = 0.5
    private let maxAusschlagGrad = 20.0

    private var eben: Bool {
        abs(sensor.neigungGrad) <= toleranzGrad && abs(sensor.rollGrad) <= toleranzGrad
    }

    var body: some View {
        VStack(spacing: 24) {
            if sensor.verfuegbar {
                GeometryReader { geo in
                    let seite = min(geo.size.width, geo.size.height)
                    ZStack {
                        Circle()
                            .strokeBorder(MykColor.line, lineWidth: 2)
                        Circle()
                            .strokeBorder(MykColor.line.opacity(0.5), lineWidth: 1)
                            .frame(width: seite * 0.5, height: seite * 0.5)
                        Circle()
                            .fill(eben ? MykColor.ok : MykColor.brand)
                            .frame(width: seite * 0.14, height: seite * 0.14)
                            .offset(
                                x: versatz(sensor.rollGrad, spanne: seite),
                                y: versatz(sensor.neigungGrad, spanne: seite)
                            )
                            .animation(.easeOut(duration: 0.1), value: sensor.neigungGrad)
                            .animation(.easeOut(duration: 0.1), value: sensor.rollGrad)
                    }
                    .frame(width: seite, height: seite)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .frame(maxWidth: 280, maxHeight: 280)

                VStack(spacing: 4) {
                    Text(eben ? "EBEN" : "NICHT EBEN")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(eben ? MykColor.ok : MykColor.brand)
                    Text("Neigung \(sensor.neigungGrad, specifier: "%.1f")° · Roll \(sensor.rollGrad, specifier: "%.1f")°")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(MykColor.muted)
                }
            } else {
                ContentUnavailableView(
                    "Bewegungssensor nicht verfügbar",
                    systemImage: "level",
                    description: Text("Dieses Gerät liefert keine Bewegungsdaten.")
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MykColor.paper)
        .navigationTitle("Wasserwaage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { sensor.starten() }
        .onDisappear { sensor.stoppen() }
    }

    private func versatz(_ grad: Double, spanne: CGFloat) -> CGFloat {
        let begrenzt = max(-maxAusschlagGrad, min(maxAusschlagGrad, grad))
        return CGFloat(begrenzt / maxAusschlagGrad) * (spanne * 0.42)
    }
}

#Preview {
    NavigationStack {
        WasserwaageView()
    }
}
