import SwiftUI
import UniformTypeIdentifiers

/// "Satellit koppeln" — ein Pairing statt vieler Einzel-Logins. Die
/// Mothership erzeugt ein verschluesseltes Paket (QR/AirDrop) + eine PIN;
/// hier wird es geoeffnet und die Zugaenge landen im Schluesselbund.
struct KopplungImportView: View {
    @State private var umschlag: KopplungsUmschlag?
    @State private var eingabeText = ""
    @State private var pin = ""
    @State private var zeigeDateiwahl = false
    @State private var uebernommen: [String]?
    @State private var benutzer: String?
    @State private var fehler: String?

    @State private var bindung = MothershipBindung()
    @State private var freigaben = FreigabeStore()
    @State private var wechselPaket: KopplungsInhalt?   // wartet auf Bestaetigung

    var body: some View {
        Form {
            statusSektion
            if uebernommen == nil {
                paketSektion
                if umschlag != nil { pinSektion }
            } else {
                erfolgSektion
            }
            if let fehler {
                Text(fehler).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Satellit koppeln")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $zeigeDateiwahl, allowedContentTypes: [.json, .data], allowsMultipleSelection: false) { ergebnis in
            dateiLaden(ergebnis)
        }
        .confirmationDialog(
            "Nutzer wechseln?",
            isPresented: Binding(get: { wechselPaket != nil }, set: { if !$0 { wechselPaket = nil } }),
            titleVisibility: .visible
        ) {
            Button("Zu \(wechselPaket?.benutzerName ?? "") wechseln", role: .destructive) {
                if let p = wechselPaket { anwendenUndBinden(p) }
                wechselPaket = nil
            }
            Button("Abbrechen", role: .cancel) { wechselPaket = nil }
        } message: {
            Text("Dieses Geraet ist als persoenlich auf \(bindung.besitzer ?? "") gebrieft. Wirklich wechseln?")
        }
    }

    private var statusSektion: some View {
        Section {
            if let besitzer = bindung.besitzer {
                HStack {
                    Label(besitzer, systemImage: "person.fill")
                    Spacer()
                    if let rolle = bindung.rolle { Text(rolle).font(.caption).foregroundStyle(MykColor.muted) }
                }
                if let firma = bindung.firma {
                    Label(firma, systemImage: "building.2.fill").font(.caption).foregroundStyle(MykColor.muted)
                }
                Button("Abmelden (Zugaenge wischen)", role: .destructive) {
                    bindung.abmelden(freigaben: freigaben)
                    uebernommen = nil; benutzer = nil; umschlag = nil; eingabeText = ""; fehler = nil
                }
            } else {
                Text("Noch nicht gebrieft.").font(.caption).foregroundStyle(MykColor.muted)
            }
            Picker("Geraetetyp", selection: $bindung.modus) {
                ForEach(GeraeteModus.allCases) { Text($0.titel).tag($0) }
            }
        } header: {
            Text("Dieses Geraet")
        } footer: {
            Text(bindung.modus == .geteilt
                 ? "Geteilt: bei jedem Nutzerwechsel neu koppeln; Abmelden wischt die privaten Zugaenge."
                 : "Persoenlich: bleibt gebrieft; ein Nutzerwechsel wird abgefragt.")
        }
    }

    private var paketSektion: some View {
        Section {
            Button {
                zeigeDateiwahl = true
            } label: {
                Label("AirDrop-Paket oeffnen", systemImage: "airplayaudio")
            }
            TextField("...oder Paket-Text einfuegen", text: $eingabeText, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(.caption, design: .monospaced))
            if !eingabeText.isEmpty {
                Button("Text uebernehmen") { textLaden() }
            }
            if umschlag != nil {
                Label("Paket erkannt", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(MykColor.ok)
            }
        } header: {
            Text("Schritt 1: Paket von der Mothership")
        } footer: {
            Text("Am Mac: mykilOS -> Satellit koppeln -> QR/AirDrop. Schick das Paket per AirDrop aufs iPhone oder fuege den Text ein.")
        }
    }

    private var pinSektion: some View {
        Section {
            SecureField("6-stellige PIN vom Mac", text: $pin)
                .keyboardType(.numberPad)
            Button("Koppeln") { koppeln() }
                .buttonStyle(.borderedProminent).tint(MykColor.brand)
                .disabled(pin.count < 4)
        } header: {
            Text("Schritt 2: PIN eingeben")
        } footer: {
            Text("Die PIN steht am Mac neben dem Paket. Ohne sie laesst sich das Paket nicht oeffnen.")
        }
    }

    private var erfolgSektion: some View {
        Section {
            Label("Gekoppelt", systemImage: "checkmark.seal.fill")
                .foregroundStyle(MykColor.ok)
                .font(.headline)
            if let benutzer {
                Text("Angemeldet als \(benutzer)").font(.callout)
            }
            ForEach(uebernommen ?? [], id: \.self) { instrument in
                Label(instrument, systemImage: "key.fill").font(.callout)
            }
        } header: {
            Text("Uebernommene Zugaenge")
        } footer: {
            Text("Alles im iPhone-Schluesselbund. Google meldest du separat an (eigener Sign-in). Clockodo bleibt nutzer-privat.")
        }
    }

    private func dateiLaden(_ ergebnis: Result<[URL], Error>) {
        fehler = nil
        do {
            guard let url = try ergebnis.get().first else { return }
            let zugriff = url.startAccessingSecurityScopedResource()
            defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
            let text = try String(contentsOf: url, encoding: .utf8)
            guard let u = KopplungsKrypto.umschlagAusText(text) else {
                fehler = KopplungsFehler.ungueltigesPaket.errorDescription
                return
            }
            umschlag = u
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func textLaden() {
        fehler = nil
        guard let u = KopplungsKrypto.umschlagAusText(eingabeText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            fehler = KopplungsFehler.ungueltigesPaket.errorDescription
            return
        }
        umschlag = u
    }

    private func koppeln() {
        fehler = nil
        guard let umschlag else { return }
        let inhalt: KopplungsInhalt
        do {
            inhalt = try KopplungsKrypto.entschluessle(umschlag, pin: pin)
        } catch {
            fehler = Fehlertext.deutsch(error)
            return
        }
        switch bindung.pruefe(firma: inhalt.firma, benutzer: inhalt.benutzerName) {
        case .fremderKosmos(let vorher, let jetzt):
            fehler = "Dieses Paket gehoert zu \(jetzt), das Geraet aber zu \(vorher). Kosmos-Wechsel ist blockiert - erst abmelden."
        case .nutzerWechsel:
            if bindung.modus == .geteilt {
                // Geteiltes Geraet: Wechsel = Login. Vorherigen Nutzer
                // de-briefen, dann neu uebernehmen.
                bindung.abmelden(freigaben: freigaben)
                anwendenUndBinden(inhalt)
            } else {
                // Persoenliches Geraet: nachfragen.
                wechselPaket = inhalt
            }
        case .inOrdnung:
            anwendenUndBinden(inhalt)
        }
    }

    private func anwendenUndBinden(_ inhalt: KopplungsInhalt) {
        do {
            let liste = try KopplungsAnwender.anwenden(inhalt)
            bindung.binde(firma: inhalt.firma, besitzer: inhalt.benutzerName, rolle: inhalt.rolle)
            benutzer = inhalt.benutzerName
            uebernommen = liste
            pin = ""
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack { KopplungImportView() }
}
