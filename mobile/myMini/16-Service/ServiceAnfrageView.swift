import SwiftUI

/// Gefuehrte Service-Anfrage von der Baustelle: Projekt -> Servicepartner ->
/// Geraet (aus dem Scan-Log uebernehmbar) -> Problem per Diktat -> Fotos ->
/// vollstaendig vorbefuellte E-Mail. Ehrliche Grenze: es gibt keine
/// oeffentlichen Ticket-APIs der Hersteller — der universelle Kanal ist die
/// Mail an den Werkskundendienst/Haendler. Gesendet wird erst, wenn Johannes
/// im Mail-Sheet auf Senden tippt (Karte->Bestaetigung, wie ueberall).
struct ServiceAnfrageView: View {
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    @State private var partnerStore = ServicePartnerStore()
    @State private var barcodeLog = BarcodeLogStore()
    @State private var kontakteStore = KontakteStore()

    @State private var suche = ""
    @State private var gewaehltesProjekt: Project?
    @State private var gewaehlterPartner: ServicePartner?

    @State private var neuName = ""
    @State private var neuEmail = ""
    @State private var neuMarken = ""

    @State private var marke = ""
    @State private var modell = ""
    @State private var seriennummer = ""
    @State private var problem = ""
    @State private var zeigeDiktat = false
    @State private var gewaehlteFotoIDs: Set<UUID> = []

    @State private var zeigeMail = false
    @State private var gesendetBestaetigt = false
    @State private var fehler: String?

    private var projekte: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    private var projektFotos: [FeldFoto] {
        guard let projekt = gewaehltesProjekt else { return [] }
        return feldFotoStore.fotos
            .filter { $0.projectNumber == projekt.projectNumber }
            .sorted { $0.aufgenommenAm > $1.aufgenommenAm }
    }

    private var bereit: Bool {
        gewaehltesProjekt != nil
            && gewaehlterPartner != nil
            && !marke.trimmingCharacters(in: .whitespaces).isEmpty
            && !problem.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            projektSektion
            if gewaehltesProjekt != nil { partnerSektion }
            if gewaehlterPartner != nil { geraetSektion; problemSektion; sendenSektion }
            if !partnerStore.anfragen.isEmpty { logSektion }
            if let fehler {
                Text(fehler).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Service-Anfrage")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $zeigeDiktat) {
            SprachaufnahmeView(
                onFertig: { text in
                    problem = problem.isEmpty ? text : problem + " " + text
                    zeigeDiktat = false
                },
                onAbbruch: { zeigeDiktat = false }
            )
        }
        .sheet(isPresented: $zeigeMail) {
            if let partner = gewaehlterPartner {
                MailKomposition(
                    empfaenger: partner.email,
                    betreff: mailBetreff,
                    text: mailText,
                    anhaenge: mailAnhaenge,
                    onFertig: { gesendet in
                        zeigeMail = false
                        if gesendet { anfrageLoggen() }
                    }
                )
                .ignoresSafeArea()
            }
        }
        .task { if kontakteStore.kontakte.isEmpty { await kontakteStore.aktualisieren() } }
    }

    // MARK: - Schritte

    private var projektSektion: some View {
        Section {
            TextField("Projekt suchen...", text: $suche)
            ForEach(projekte.prefix(5)) { project in
                Button {
                    gewaehltesProjekt = project
                    gewaehlteFotoIDs = []
                    gesendetBestaetigt = false
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
    }

    private var partnerSektion: some View {
        Section {
            ForEach(partnerStore.partner) { partner in
                Button {
                    gewaehlterPartner = partner
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(partner.name)
                            Text(partner.marken.isEmpty ? partner.email : "\(partner.marken) - \(partner.email)")
                                .font(.caption)
                                .foregroundStyle(MykColor.muted)
                        }
                        Spacer()
                        if gewaehlterPartner?.id == partner.id {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.brand)
                        }
                    }
                }
                .foregroundStyle(MykColor.ink)
            }
            DisclosureGroup("Neuen Partner anlegen") {
                TextField("Name (z. B. Miele Werkkundendienst)", text: $neuName)
                TextField("E-Mail-Adresse", text: $neuEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Marken (z. B. Miele, Bora)", text: $neuMarken)
                Button("Partner speichern") { partnerSpeichern() }
                    .disabled(neuName.trimmingCharacters(in: .whitespaces).isEmpty || !neuEmail.contains("@"))
            }
        } header: {
            Text("Schritt 2: Servicepartner")
        } footer: {
            Text("Einmal angelegt, immer wiederverwendbar. Lokal auf dem Geraet gespeichert.")
        }
    }

    private var geraetSektion: some View {
        Section {
            TextField("Marke (z. B. Miele)", text: $marke)
            TextField("Modell (z. B. G 7310 SCi)", text: $modell)
            TextField("Seriennummer", text: $seriennummer)
            if !barcodeLog.treffer.isEmpty {
                Menu {
                    ForEach(barcodeLog.treffer.suffix(8).reversed()) { treffer in
                        Button("\(treffer.wert) (\(treffer.symbologie))") {
                            seriennummer = treffer.wert
                        }
                    }
                } label: {
                    Label("Aus Scan-Log uebernehmen", systemImage: "barcode.viewfinder")
                }
            }
        } header: {
            Text("Schritt 3: Geraet")
        } footer: {
            Text("Typenschild vorher mit dem Barcode-Scanner erfassen - dann steht die Seriennummer hier zur Uebernahme bereit.")
        }
    }

    private var problemSektion: some View {
        Section {
            HStack(alignment: .top) {
                TextField("Was ist kaputt? Was wurde schon probiert?", text: $problem, axis: .vertical)
                    .lineLimit(3...8)
                Button {
                    zeigeDiktat = true
                } label: {
                    Image(systemName: "mic.fill").foregroundStyle(MykColor.brand)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Problem diktieren")
            }
            ForEach(projektFotos.prefix(8)) { foto in
                Button {
                    if gewaehlteFotoIDs.contains(foto.id) {
                        gewaehlteFotoIDs.remove(foto.id)
                    } else {
                        gewaehlteFotoIDs.insert(foto.id)
                    }
                } label: {
                    HStack {
                        Image(systemName: gewaehlteFotoIDs.contains(foto.id) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(gewaehlteFotoIDs.contains(foto.id) ? MykColor.brand : MykColor.muted)
                        Text("\(foto.kanonZiel.titel) - \(foto.aufgenommenAm.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                    }
                }
                .foregroundStyle(MykColor.ink)
            }
        } header: {
            Text("Schritt 4: Problem + Fotos")
        } footer: {
            Text(projektFotos.isEmpty
                 ? "Keine Feld-Fotos zu diesem Projekt - Fotos vorher ueber die Fang-Karte aufnehmen."
                 : "Angehakte Feld-Fotos gehen als Anhang mit.")
        }
    }

    private var sendenSektion: some View {
        Section {
            if MailKomposition.kannSenden {
                Button("Anfrage-Mail oeffnen") { zeigeMail = true }
                    .buttonStyle(.borderedProminent)
                    .tint(MykColor.brand)
                    .disabled(!bereit)
            } else {
                Label("Kein Mail-Konto auf diesem iPhone eingerichtet - Einstellungen > Apps > Mail > Accounts.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(MykColor.crit)
            }
            if gesendetBestaetigt {
                Label("Anfrage gesendet und im Log vermerkt", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(MykColor.ok)
            }
        } header: {
            Text("Schritt 5: Pruefen und senden")
        } footer: {
            Text("Die Mail oeffnet sich vollstaendig vorbefuellt - gesendet wird erst mit deinem Tipp auf Senden.")
        }
    }

    private var logSektion: some View {
        Section {
            ForEach(partnerStore.anfragen.reversed()) { anfrage in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(anfrage.geraet) an \(anfrage.partnerName)")
                        .font(.subheadline.weight(.semibold))
                    Text("\(anfrage.projectTitel) - \(anfrage.gesendetAm.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(MykColor.muted)
                }
            }
        } header: {
            Text("Bisherige Anfragen")
        }
    }

    // MARK: - Mail-Inhalt

    private var mailBetreff: String {
        let geraet = [marke, modell].filter { !$0.isEmpty }.joined(separator: " ")
        let projekt = gewaehltesProjekt?.title ?? ""
        return "Service-Anfrage: \(geraet) - Projekt \(projekt)"
    }

    /// Kunde/Adresse aus dem Kontakte-Cache, wenn ein Kontaktname zum
    /// Projekttitel passt — nur ein Komfort-Vorschlag, im Mail-Sheet
    /// jederzeit korrigierbar.
    private var passenderKontakt: KundenKontakt? {
        guard let projekt = gewaehltesProjekt, projekt.title.count >= 3 else { return nil }
        let titel = projekt.title.lowercased()
        return kontakteStore.kontakte.first {
            $0.name.lowercased().contains(titel) || titel.contains($0.name.lowercased())
        }
    }

    private var mailText: String {
        guard let projekt = gewaehltesProjekt else { return "" }
        var zeilen = [
            "Guten Tag,",
            "",
            "hiermit melde ich einen Servicefall an:",
            "",
            "Geraet: \(marke) \(modell)".trimmingCharacters(in: .whitespaces),
        ]
        if !seriennummer.isEmpty { zeilen.append("Seriennummer: \(seriennummer)") }
        zeilen.append("")
        zeilen.append("Problembeschreibung:")
        zeilen.append(problem)
        zeilen.append("")
        zeilen.append("Einsatzort / Projekt: \(projekt.title) (\(projekt.projectNumber))")
        if let kontakt = passenderKontakt {
            if let adresse = kontakt.adresse { zeilen.append("Adresse: \(adresse)") }
            if let telefon = kontakt.telefon { zeilen.append("Kunde vor Ort: \(kontakt.name), Tel. \(telefon)") }
        }
        zeilen.append("")
        zeilen.append("Bitte um Terminvorschlag fuer den Technikereinsatz.")
        zeilen.append("")
        zeilen.append("Mit freundlichen Gruessen")
        zeilen.append("Johannes Berger - MYKILOS")
        return zeilen.joined(separator: "\n")
    }

    private var mailAnhaenge: [(daten: Data, dateiname: String)] {
        projektFotos
            .filter { gewaehlteFotoIDs.contains($0.id) }
            .compactMap { foto in
                guard let daten = try? Data(contentsOf: feldFotoStore.bildURL(fuer: foto)) else { return nil }
                return (daten: daten, dateiname: foto.dateiname)
            }
    }

    // MARK: - Aktionen

    private func partnerSpeichern() {
        fehler = nil
        do {
            let partner = ServicePartner(
                name: neuName.trimmingCharacters(in: .whitespaces),
                email: neuEmail.trimmingCharacters(in: .whitespaces),
                marken: neuMarken.trimmingCharacters(in: .whitespaces)
            )
            try partnerStore.speicherePartner(partner)
            gewaehlterPartner = partner
            neuName = ""
            neuEmail = ""
            neuMarken = ""
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func anfrageLoggen() {
        guard let projekt = gewaehltesProjekt, let partner = gewaehlterPartner else { return }
        do {
            try partnerStore.loggeAnfrage(ServiceAnfrage(
                partnerName: partner.name,
                projectTitel: projekt.title,
                geraet: [marke, modell].filter { !$0.isEmpty }.joined(separator: " ")
            ))
            gesendetBestaetigt = true
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack {
        ServiceAnfrageView(store: ProjectStore(), feldFotoStore: FeldFotoStore())
    }
}
