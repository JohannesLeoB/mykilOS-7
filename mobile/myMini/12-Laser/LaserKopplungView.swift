import SwiftUI

/// Bluetooth-Laser-Kopplung (#14-Fundament) — bewusst noch OHNE Mess-Werte.
/// Scannt, verbindet, zeigt die echten GATT-Services/Characteristics des
/// verbundenen Geräts. Sobald feststeht, welcher Laser (Leica DISTO, Bosch
/// GLM, …) es wird, liefert diese Liste die Grundlage für das eigentliche
/// Protokoll-Parsing — kein erratenes Herstellerprotokoll.
struct LaserKopplungView: View {
    let scanner: BluetoothLaserScanner

    var body: some View {
        List {
            if let verbundenesGeraet = scanner.verbundenesGeraet {
                Section {
                    HStack {
                        Text(verbundenesGeraet.name).font(.subheadline.weight(.semibold))
                        Spacer()
                        Button("Trennen", role: .destructive) { scanner.trennen() }
                            .font(.caption)
                    }
                    if let millimeter = scanner.letzterMesswertMM {
                        HStack {
                            Label("\(millimeter) mm", systemImage: "ruler.fill")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(MykColor.brand)
                            Spacer()
                            if let zeit = scanner.letzterMesswertZeit {
                                Text(zeit.formatted(date: .omitted, time: .standard))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(MykColor.muted)
                            }
                        }
                        HStack(spacing: 6) {
                            Image(systemName: scanner.letzterMesswertVerifiziert ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            Text("\(scanner.messwertQuelle ?? "BLE-Laser") - \(scanner.letzterMesswertVerifiziert ? "verifiziert" : "generisch, bitte gegen Geraeteanzeige pruefen")")
                        }
                        .font(.caption)
                        .foregroundStyle(scanner.letzterMesswertVerifiziert ? MykColor.ok : MykColor.ocker)
                    }
                } header: {
                    Text("Verbunden")
                } footer: {
                    Text("Universeller Empfaenger: die App hoert auf allen Mess-Kanaelen des Geraets. Leica ist verifiziert; andere BLE-Laser werden best effort ausgelesen (Wert erscheint auch in der Foto-Bemassung). Geraet moeglichst auf METER stellen. Kommt kein Wert an: die Service-Liste unten zeigt, was das Geraet funkt - schick mir einen Screenshot, dann verdrahte ich es fest.")
                }

                Section {
                    if scanner.entdeckteServices.isEmpty {
                        Text("Suche nach Services…").font(.footnote).foregroundStyle(MykColor.muted)
                    } else {
                        ForEach(scanner.entdeckteServices) { service in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.id)
                                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                                ForEach(service.characteristics) { charakteristik in
                                    HStack {
                                        Text(charakteristik.id)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(MykColor.muted)
                                        Spacer()
                                        Text(charakteristik.eigenschaften.joined(separator: ", "))
                                            .font(.caption2)
                                            .foregroundStyle(MykColor.brand)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Gefundene Services")
                } footer: {
                    Text("Diese IDs braucht die nächste Session, um das echte Mess-Protokoll deines Geräts anzubinden.")
                }
            } else {
                Section {
                    Button(scanner.scanntGerade ? "Suche läuft…" : "Nach Geräten suchen") {
                        scanner.scanStarten()
                    }
                    .disabled(scanner.scanntGerade)
                }

                if !scanner.gefundeneGeraete.isEmpty {
                    Section("Gefundene Geräte") {
                        ForEach(scanner.gefundeneGeraete) { geraet in
                            Button {
                                scanner.verbinden(geraet)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(geraet.name)
                                        if let hersteller = geraet.erkannterHersteller {
                                            Text(hersteller)
                                                .font(.caption2)
                                                .foregroundStyle(MykColor.brand)
                                        }
                                    }
                                    Spacer()
                                    Text("\(geraet.rssi) dBm")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(MykColor.muted)
                                }
                            }
                            .foregroundStyle(MykColor.ink)
                        }
                    }
                }
            }

            if let fehler = scanner.fehler {
                Text(fehler).font(.footnote).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Laser koppeln")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { scanner.scanStoppen() }
    }
}

#Preview {
    NavigationStack {
        LaserKopplungView(scanner: BluetoothLaserScanner())
    }
}
