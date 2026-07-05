import SwiftUI

/// §14 Datenschutz-Transparenz: ein Fähigkeiten-Panel — ein Blick auf ALLES,
/// was gerade verbunden ist, statt verstreut in Postbox und Assistent. Ändert
/// nichts an den bestehenden Einstiegen dort (bleiben als Schnellzugriff),
/// das hier ist die zusätzliche Gesamtübersicht.
struct VerbindungenView: View {
    let standortStore: ProjektStandortStore
    let geofenceWaechter: GeofenceWaechter

    @State private var airtableVerbunden = false
    @State private var claudeVerbunden = false
    @State private var googleVerbunden = false
    @State private var zeigeAirtableEinstellungen = false
    @State private var zeigeClaudeEinstellungen = false
    @State private var zeigeGoogleEinstellungen = false
    @State private var zeigeStandortErklaerung = false
    // App-weite Instanz: die Laser-Verbindung soll die Navigation
    // ueberleben (koppeln hier, messen in der Foto-Bemassung).
    @State private var laserScanner = BluetoothLaserScanner.shared

    private let airtableStore: AirtablePostboxCredentialsStoring = KeychainAirtablePostboxCredentialsStore()
    private let claudeStore: ClaudeCredentialsStoring = KeychainClaudeCredentialsStore()
    private let googleStore: GoogleCredentialsStoring = KeychainGoogleCredentialsStore()

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    KopplungImportView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Satellit koppeln").font(.subheadline.weight(.semibold))
                            Text("Ein Pairing mit der Mothership statt Einzel-Logins")
                                .font(.caption).foregroundStyle(MykColor.muted)
                        }
                    } icon: {
                        Image(systemName: "qrcode.viewfinder").foregroundStyle(MykColor.brand)
                    }
                }
            } footer: {
                Text("Am Mac ein verschluesseltes Paket erzeugen, hier per AirDrop/Text + PIN uebernehmen - Airtable, Claude und Firefly auf einen Schlag.")
            }

            Section {
                zeile(
                    titel: "Airtable Postbox",
                    untertitel: "Zeit-Sync in die Adapter-Base",
                    verbunden: airtableVerbunden
                ) { zeigeAirtableEinstellungen = true }

                zeile(
                    titel: "Claude Assistent",
                    untertitel: "Gespräch im Cockpit",
                    verbunden: claudeVerbunden
                ) { zeigeClaudeEinstellungen = true }

                zeile(
                    titel: "Google Drive",
                    untertitel: "Feld-Foto-Upload (★3) — noch ungetestet",
                    verbunden: googleVerbunden
                ) { zeigeGoogleEinstellungen = true }
            } header: {
                Text("Verbindungen")
            } footer: {
                Text("Jede Verbindung liegt nur in deinem eigenen iPhone-Schlüsselbund — nie im Code, nie im Chat, nie im Repo. Ein Fingertipp trennt sie wieder.")
            }

            Section {
                Toggle(isOn: Binding(
                    get: { geofenceWaechter.aktiv },
                    set: { neu in
                        if neu {
                            geofenceWaechter.aktivieren()
                        } else {
                            geofenceWaechter.deaktivieren()
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Standort-Wächter").font(.subheadline.weight(.semibold))
                        Text("Erkennt, wenn du bei einem gemerkten Projekt-Standort bist")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                }
                if geofenceWaechter.aktiv {
                    Text("\(standortStore.orte.count) Standort(e) gemerkt — in der Projektliste bei einem Projekt aufklappen und 'Diesen Ort merken' antippen.")
                        .font(.caption)
                        .foregroundStyle(MykColor.muted)
                }
                Button("Was macht das genau?") { zeigeStandortErklaerung = true }
                    .font(.caption)
            } header: {
                Text("Standort")
            } footer: {
                Text("Standardmäßig AUS. Läuft komplett auf dem Gerät, kein Kalender-Abgleich (bräuchte ein eigenes Google-Konto-Okay). Ein Antippen schaltet alles wieder ab — auch alle überwachten Orte.")
            }

            Section {
                Toggle(isOn: Binding(
                    get: { laserScanner.aktiv },
                    set: { neu in
                        if neu {
                            laserScanner.aktivieren()
                        } else {
                            laserScanner.deaktivieren()
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bluetooth-Laser").font(.subheadline.weight(.semibold))
                        Text("Leica DISTO: Live-Messwerte · andere: Suchen & Verbinden")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                }
                if laserScanner.aktiv {
                    NavigationLink("Gerät koppeln") {
                        LaserKopplungView(scanner: laserScanner)
                    }
                }
            } header: {
                Text("Laser (Fundament)")
            } footer: {
                Text("Standardmäßig AUS. Leica-DISTO-Protokoll ist verdrahtet (dokumentiertes BLE-Kit, Live-Verifikation im Studio ausstehend) — Messwert erscheint beim Koppeln und in der Foto-Bemaßung. Bosch GLM: verbinden + Service-Liste ablesen, dann verdrahten wir ihn als naechsten.")
            }

            Section {
                HStack {
                    Text("mykilOS mobile")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(MykColor.muted)
                        .font(.system(.footnote, design: .monospaced))
                }
            } header: {
                Text("Über")
            } footer: {
                Text("Der Satellit zum mykilOS Mothership — persönliches Cockpit, geteilte Instrumente.")
            }
        }
        .navigationTitle("Verbindungen")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $zeigeAirtableEinstellungen) {
            AirtablePostboxSettingsView(credentialsStore: airtableStore, verbunden: $airtableVerbunden)
        }
        .sheet(isPresented: $zeigeClaudeEinstellungen) {
            ClaudeSettingsView(credentialsStore: claudeStore, verbunden: $claudeVerbunden)
        }
        .sheet(isPresented: $zeigeGoogleEinstellungen) {
            GoogleSignInSettingsView(credentialsStore: googleStore, verbunden: $googleVerbunden)
        }
        .sheet(isPresented: $zeigeStandortErklaerung) {
            NavigationStack {
                List {
                    Text("Standardmäßig AUS — iOS fragt erst beim Einschalten nach \"Immer\"-Standortzugriff.")
                    Text("Du merkst pro Projekt einmal den Ort (aufklappen → \"Diesen Ort merken\").")
                    Text("Danach erkennt das Gerät selbst, wann du kommst und gehst — auch wenn die App geschlossen ist.")
                    Text("Nach einem abgeschlossenen Besuch erscheint eine Karte im Herzschlag-Bildschirm — nie automatisch, du bestätigst oder verwirfst.")
                    Text("Kein Kalender-Abgleich — das bräuchte ein eigenes Google-Konto-Okay, bleibt draußen.")
                    Text("Ausschalten löscht sofort alle überwachten Orte, kein Umweg über iOS-Einstellungen.")
                }
                .navigationTitle("Standort-Wächter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fertig") { zeigeStandortErklaerung = false }
                    }
                }
            }
        }
        .task {
            airtableVerbunden = (try? airtableStore.load()) != nil
            claudeVerbunden = (try? claudeStore.load()) != nil
            googleVerbunden = (try? googleStore.load()) != nil
        }
    }

    private func zeile(
        titel: String, untertitel: String, verbunden: Bool, oeffnen: @escaping () -> Void
    ) -> some View {
        Button(action: oeffnen) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel).font(.subheadline.weight(.semibold)).foregroundStyle(MykColor.ink)
                    Text(untertitel).font(.caption).foregroundStyle(MykColor.muted)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: verbunden ? "checkmark.circle.fill" : "circle")
                    Text(verbunden ? "Verbunden" : "Nicht verbunden")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(verbunden ? MykColor.ok : MykColor.muted)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let standortStore = ProjektStandortStore()
    NavigationStack {
        VerbindungenView(
            standortStore: standortStore,
            geofenceWaechter: GeofenceWaechter(standortStore: standortStore, aufenthaltStore: StandortAufenthaltStore())
        )
    }
}
