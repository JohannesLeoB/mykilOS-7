import CoreLocation
import SwiftUI

/// Sonnenverlauf-Planer (#42): Standort + Datum + Uhrzeit -> wo steht die
/// Sonne. Fuer die Frage "welches Fenster bekommt Nachmittagssonne", die
/// Verschattungs-Skizze im Kopf, die Terrassen-Entscheidung. Rein
/// on-device: Standort vom Geraet, Rechnung lokal (NOAA), kein Netz.
struct SonnenverlaufView: View {
    @State private var sensor = EinmaligerOrtsSensor()
    @State private var koordinate: CLLocationCoordinate2D?
    @State private var datum = Date()
    @State private var laedtStandort = false
    @State private var fehler: String?

    private var stand: Sonnenstand? {
        guard let koordinate else { return nil }
        return SonnenstandRechner.berechne(
            datum: datum, breitengrad: koordinate.latitude, laengengrad: koordinate.longitude)
    }

    private var aufUnter: (aufgang: Date?, untergang: Date?)? {
        guard let koordinate else { return nil }
        return SonnenstandRechner.aufUndUntergang(
            datum: datum, breitengrad: koordinate.latitude, laengengrad: koordinate.longitude)
    }

    var body: some View {
        Form {
            standortSektion
            if koordinate != nil {
                zeitSektion
                if let stand { standSektion(stand) }
                tagesbogenSektion
            }
            hinweisSektion
        }
        .navigationTitle("Sonnenverlauf")
        .navigationBarTitleDisplayMode(.inline)
        .task { if koordinate == nil { await standortHolen() } }
    }

    private var standortSektion: some View {
        Section {
            if let koordinate {
                HStack {
                    Label(String(format: "%.4f, %.4f", koordinate.latitude, koordinate.longitude),
                          systemImage: "location.fill")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(MykColor.muted)
                    Spacer()
                    Button("Neu") { Task { await standortHolen() } }
                        .font(.caption.weight(.semibold))
                }
            } else if laedtStandort {
                ProgressView("Standort wird ermittelt...").font(.footnote)
            } else {
                Button {
                    Task { await standortHolen() }
                } label: {
                    Label("Aktuellen Standort verwenden", systemImage: "location")
                }
            }
            if let fehler {
                Text(fehler).font(.caption).foregroundStyle(MykColor.crit)
            }
        } header: {
            Text("Standort")
        } footer: {
            Text("Am besten vor Ort im Raum - dann rechnet die Sonne fuer genau diese Position.")
        }
    }

    private var zeitSektion: some View {
        Section {
            DatePicker("Datum", selection: $datum, displayedComponents: .date)
            DatePicker("Uhrzeit", selection: $datum, displayedComponents: .hourAndMinute)
            Button("Jetzt") { datum = Date() }
                .font(.caption.weight(.semibold))
        } header: {
            Text("Zeitpunkt")
        }
    }

    private func standSektion(_ stand: Sonnenstand) -> some View {
        Section {
            SonnenKompass(azimut: stand.azimut, hoehe: stand.hoehe)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            HStack {
                Text("Richtung")
                Spacer()
                Text("\(stand.himmelsrichtung) (\(Int(stand.azimut.rounded()))\u{00B0})")
                    .foregroundStyle(MykColor.brand)
                    .font(.callout.weight(.semibold))
            }
            HStack {
                Text("Hoehe ueber Horizont")
                Spacer()
                Text("\(Int(stand.hoehe.rounded()))\u{00B0}")
                    .foregroundStyle(stand.istUeberHorizont ? MykColor.brand : MykColor.muted)
                    .font(.callout.weight(.semibold))
            }
            if !stand.istUeberHorizont {
                Label("Sonne steht unter dem Horizont", systemImage: "moon.stars.fill")
                    .font(.caption)
                    .foregroundStyle(MykColor.muted)
            }
            if let aufUnter {
                HStack {
                    Label(zeitText(aufUnter.aufgang), systemImage: "sunrise.fill")
                    Spacer()
                    Label(zeitText(aufUnter.untergang), systemImage: "sunset.fill")
                }
                .font(.caption)
                .foregroundStyle(MykColor.muted)
            }
        } header: {
            Text("Sonnenstand")
        }
    }

    private var tagesbogenSektion: some View {
        Section {
            if let koordinate {
                TagesBogen(datum: datum, breitengrad: koordinate.latitude, laengengrad: koordinate.longitude)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        } header: {
            Text("Tagesbogen")
        } footer: {
            Text("Sonnenhoehe ueber den Tag. Die Markierung zeigt den gewaehlten Zeitpunkt.")
        }
    }

    private var hinweisSektion: some View {
        Section {
            Text("Standard-Astronomie (NOAA), genau auf etwa eine Bogenminute. KEINE Verschattung durch Nachbarhaeuser, Baeume oder Dachueberstaende - die Sonne steht hier richtig, ob sie wirklich ins Fenster faellt, entscheidet die Umgebung vor Ort.")
                .font(.caption2)
                .foregroundStyle(MykColor.muted)
        }
    }

    private func zeitText(_ datum: Date?) -> String {
        guard let datum else { return "--:--" }
        return datum.formatted(date: .omitted, time: .shortened)
    }

    private func standortHolen() async {
        laedtStandort = true
        fehler = nil
        defer { laedtStandort = false }
        guard let ort = await sensor.hole() else {
            fehler = "Standort nicht ermittelbar - Standort-Berechtigung erteilt?"
            return
        }
        koordinate = ort
    }
}

/// Kompass-Scheibe mit Sonnenpunkt: Richtung ueber den Winkel, Hoehe ueber
/// den Radius (Horizont am Rand, Zenit in der Mitte).
struct SonnenKompass: View {
    let azimut: Double
    let hoehe: Double

    var body: some View {
        GeometryReader { geo in
            let seite = min(geo.size.width, geo.size.height)
            let mitte = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = seite / 2 - 20
            // Hoehe 0 (Horizont) -> aussen, 90 (Zenit) -> Mitte.
            let hoeheAnteil = max(0, min(90, hoehe)) / 90
            let sonnenRadius = radius * (1 - hoeheAnteil)
            let winkel = (azimut - 90) * .pi / 180  // 0 Grad = Nord = oben
            let sonne = CGPoint(
                x: mitte.x + sonnenRadius * cos(winkel),
                y: mitte.y + sonnenRadius * sin(winkel))

            ZStack {
                Circle()
                    .strokeBorder(MykColor.line, lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(mitte)
                Circle()
                    .strokeBorder(MykColor.line.opacity(0.5), lineWidth: 1)
                    .frame(width: radius, height: radius)
                    .position(mitte)

                himmelsLabel("N", winkel: -90, mitte: mitte, radius: radius)
                himmelsLabel("O", winkel: 0, mitte: mitte, radius: radius)
                himmelsLabel("S", winkel: 90, mitte: mitte, radius: radius)
                himmelsLabel("W", winkel: 180, mitte: mitte, radius: radius)

                if hoehe > 0 {
                    Path { p in
                        p.move(to: mitte)
                        p.addLine(to: sonne)
                    }
                    .stroke(MykColor.brand.opacity(0.4), lineWidth: 2)
                    Circle()
                        .fill(MykColor.brand)
                        .frame(width: 20, height: 20)
                        .position(sonne)
                        .shadow(color: MykColor.brand.opacity(0.5), radius: 6)
                }
            }
        }
    }

    private func himmelsLabel(_ text: String, winkel: Double, mitte: CGPoint, radius: CGFloat) -> some View {
        let r = winkel * .pi / 180
        let punkt = CGPoint(x: mitte.x + (radius + 12) * cos(r), y: mitte.y + (radius + 12) * sin(r))
        return Text(text)
            .font(.system(.caption, design: .monospaced).weight(.semibold))
            .foregroundStyle(MykColor.muted)
            .position(punkt)
    }
}

/// Sonnenhoehe ueber den ganzen Tag (alle 15 Minuten gesampelt), mit einer
/// Markierung am gewaehlten Zeitpunkt.
struct TagesBogen: View {
    let datum: Date
    let breitengrad: Double
    let laengengrad: Double

    private var punkte: [(anteil: Double, hoehe: Double)] {
        let kal = Calendar.current
        let start = kal.startOfDay(for: datum)
        var ergebnis: [(Double, Double)] = []
        var minute = 0
        while minute <= 24 * 60 {
            let zeitpunkt = start.addingTimeInterval(Double(minute) * 60)
            let stand = SonnenstandRechner.berechne(
                datum: zeitpunkt, breitengrad: breitengrad, laengengrad: laengengrad)
            ergebnis.append((Double(minute) / (24 * 60), stand.hoehe))
            minute += 15
        }
        return ergebnis
    }

    private var jetztAnteil: Double {
        let kal = Calendar.current
        let start = kal.startOfDay(for: datum)
        return datum.timeIntervalSince(start) / (24 * 3600)
    }

    var body: some View {
        Canvas { context, size in
            let horizontY = size.height * 0.82
            // Horizontlinie.
            var horizont = Path()
            horizont.move(to: CGPoint(x: 0, y: horizontY))
            horizont.addLine(to: CGPoint(x: size.width, y: horizontY))
            context.stroke(horizont, with: .color(MykColor.line), lineWidth: 1)

            func punktFuer(_ p: (anteil: Double, hoehe: Double)) -> CGPoint {
                let x = p.anteil * size.width
                let anteil = max(0, min(90, p.hoehe)) / 90
                let y = horizontY - anteil * (horizontY - 6)
                return CGPoint(x: x, y: y)
            }

            // Kurve nur oberhalb des Horizonts.
            var kurve = Path()
            var begonnen = false
            for p in punkte where p.hoehe > 0 {
                let pt = punktFuer(p)
                if begonnen { kurve.addLine(to: pt) } else { kurve.move(to: pt); begonnen = true }
            }
            context.stroke(kurve, with: .color(MykColor.brand), lineWidth: 2.5)

            // Markierung am gewaehlten Zeitpunkt.
            let x = jetztAnteil * size.width
            var linie = Path()
            linie.move(to: CGPoint(x: x, y: 0))
            linie.addLine(to: CGPoint(x: x, y: horizontY))
            context.stroke(linie, with: .color(MykColor.brand.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }
}

#Preview {
    NavigationStack {
        SonnenverlaufView()
    }
}
