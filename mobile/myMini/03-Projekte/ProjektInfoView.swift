import CoreLocation
import QuickLook
import SwiftUI

/// Eine Projekt-Kachel im Herzschlag-Grid — kompakt, antippen oeffnet den
/// Info-Modus. Farbe = Projektart (gleiche Sprache wie ueberall).
struct ProjektKachel: View {
    let project: Project
    let pulsText: String?

    private var kindColor: Color {
        project.kind == "studioInternal" ? MykColor.plum : MykColor.ocker
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(kindColor).frame(width: 9, height: 9)
                Spacer()
                if let pulsText {
                    Text(pulsText)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(MykColor.brand)
                }
            }
            Text(project.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(MykColor.ink)
                .lineLimit(1)
            Text(project.projectNumber)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(MykColor.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MykColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MykColor.line))
    }
}

/// Der Info-Modus einer Projekt-Kachel: Kunde (anrufen/mailen/Karten-Pin),
/// Springen (Drive), lokale Zeitleiste (alles, was DU mit dem iPhone an
/// diesem Projekt getan hast), Unterlagen (Anleitungen/Scans), Standort.
/// Ehrliche Grenze: Volumen, letztes Angebot/AB und die Warenkorb-
/// Geraeteliste sind Schiffsdaten (Airtable/Drive/WorkBasket) — die zeigt
/// die Karte erst, wenn das Mothership sie in den Registry-Schnappschuss
/// exportiert. Kein Platzhalter-Zahlenwerk.
struct ProjektInfoView: View {
    let project: Project
    let shortcuts: [DriveShortcut]
    let pulsText: String?
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore
    let postbox: PostboxStore
    let standortStore: ProjektStandortStore
    let geofenceWaechter: GeofenceWaechter

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var kontakteStore = KontakteStore()
    @State private var abnahmeStore = AbnahmeprotokollStore()
    @State private var vertragsRegister = VertragsRegister()
    @State private var roomPlanStore = RoomPlanStore()
    @State private var anleitungenStore = AnleitungenStore()
    @State private var partnerStore = ServicePartnerStore()

    @State private var vorschauURL: URL?
    @State private var merktGerade = false
    @State private var standortFehler: String?
    @State private var ortsSensor = EinmaligerOrtsSensor()

    private var artLabel: String {
        // Klartext vom Schiff hat Vorrang, sonst aus `kind` abgeleitet.
        if let art = project.art, !art.isEmpty { return art }
        switch project.kind {
        case "kitchen": return "Kueche"
        case "studioInternal": return "Studio-intern"
        case "lighting": return "Licht"
        case "addendum": return "Nachtrag"
        case "lead": return "Lead"
        case "quote": return "Angebot"
        default: return project.kind
        }
    }

    /// Kunde aus dem Airtable-Kontakte-Cache — Namens-Match auf den
    /// Projekttitel, nur ein Komfort-Vorschlag.
    private var kunde: KundenKontakt? {
        guard project.title.count >= 3 else { return nil }
        let titel = project.title.lowercased()
        return kontakteStore.kontakte.first {
            $0.name.lowercased().contains(titel) || titel.contains($0.name.lowercased())
        }
    }

    private var anleitungen: [GeraeteAnleitung] {
        anleitungenStore.anleitungen.filter { $0.projectNumber == project.projectNumber }
    }

    private var raumscans: [RoomPlanAufnahme] {
        roomPlanStore.aufnahmen.filter { $0.projectNumber == project.projectNumber }
    }

    private var gemerkterStandort: ProjektStandort? {
        standortStore.orte.first { $0.projectNumber == project.projectNumber }
    }

    private struct ZeitEintrag: Identifiable {
        let id = UUID()
        let datum: Date
        let symbol: String
        let text: String
    }

    /// Lokale Projekt-Zeitleiste: alle iPhone-Spuren zu diesem Projekt,
    /// neueste zuerst. Schiffs-Ereignisse (Angebote, Mails) kommen erst
    /// mit einem Mothership-Kanal dazu.
    private var zeitleiste: [ZeitEintrag] {
        var eintraege: [ZeitEintrag] = []
        for foto in feldFotoStore.fotos where foto.projectNumber == project.projectNumber {
            eintraege.append(ZeitEintrag(datum: foto.aufgenommenAm, symbol: "camera.fill", text: "Feld-Foto (\(foto.kanonZiel.titel))"))
        }
        for mangel in abnahmeStore.eintraege where mangel.projectNumber == project.projectNumber {
            eintraege.append(ZeitEintrag(datum: mangel.erfasstAm, symbol: "list.number", text: "Mangel: \(mangel.text)"))
        }
        for vertrag in vertragsRegister.vertraege where vertrag.projectNumber == project.projectNumber {
            eintraege.append(ZeitEintrag(datum: vertrag.unterschriebenAm, symbol: "signature", text: "Vertrag signiert: \(vertrag.vertragsName)"))
        }
        for scan in raumscans {
            eintraege.append(ZeitEintrag(datum: scan.aufgenommenAm, symbol: "cube.transparent", text: "RoomPlan-Scan"))
        }
        for anleitung in anleitungen {
            eintraege.append(ZeitEintrag(datum: anleitung.importiertAm, symbol: "book.closed.fill", text: "Anleitung: \(anleitung.anzeigeName)"))
        }
        for anfrage in partnerStore.anfragen where anfrage.projectTitel == project.title {
            eintraege.append(ZeitEintrag(datum: anfrage.gesendetAm, symbol: "wrench.adjustable.fill", text: "Service-Anfrage: \(anfrage.geraet)"))
        }
        for item in postbox.items where item.kontext.localizedCaseInsensitiveContains(project.title) {
            eintraege.append(ZeitEintrag(datum: item.capturedAt, symbol: "tray.fill", text: "\(item.kind == "zeit" ? "Zeit" : "Idee"): \(item.text)"))
        }
        return eintraege.sorted { $0.datum > $1.datum }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        AuftragsReiseView(project: project, store: store, feldFotoStore: feldFotoStore)
                    } label: {
                        Label("Auftrag fuehren", systemImage: "map.fill")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(MykColor.brand)
                    }
                } footer: {
                    Text("Der rote Faden: Kunde -> Aufmass -> Entwurf -> Vertrag -> Nachbetreuung, Station fuer Station.")
                }
                kopfSektion
                kundenSektion
                springenSektion
                zeitleisteSektion
                if !anleitungen.isEmpty || !raumscans.isEmpty { unterlagenSektion }
                if geofenceWaechter.aktiv { standortSektion }
                schiffsdatenSektion
            }
            .navigationTitle(project.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .quickLookPreview($vorschauURL)
        }
    }

    // MARK: - Sektionen

    private var kopfSektion: some View {
        Section {
            HStack {
                Text("Nummer")
                Spacer()
                Text(project.projectNumber)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(MykColor.muted)
            }
            HStack {
                Text("Art")
                Spacer()
                Text(artLabel).foregroundStyle(MykColor.muted)
            }
            if let pulsText {
                HStack {
                    Text("Drive-Puls")
                    Spacer()
                    Text(pulsText).foregroundStyle(MykColor.brand)
                }
            }
        }
    }

    private var kundenSektion: some View {
        Section {
            if let kunde {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kunde.name).font(.subheadline.weight(.semibold))
                    if let adresse = kunde.adresse {
                        Text(adresse).font(.caption).foregroundStyle(MykColor.muted)
                    }
                }
                HStack(spacing: 10) {
                    if let url = kunde.telefonURL {
                        Button { openURL(url) } label: { Label("Anrufen", systemImage: "phone.fill") }
                            .buttonStyle(.bordered).tint(MykColor.ok)
                    }
                    if let url = kunde.mailURL {
                        Button { openURL(url) } label: { Label("Mail", systemImage: "envelope.fill") }
                            .buttonStyle(.bordered).tint(MykColor.brand)
                    }
                    if let url = kunde.kartenURL {
                        Button { openURL(url) } label: { Label("Karte", systemImage: "mappin.and.ellipse") }
                            .buttonStyle(.bordered).tint(MykColor.drive)
                    }
                }
                .font(.footnote.weight(.semibold))
            } else {
                Text("Kein Kontakt mit passendem Namen im Verzeichnis - im Kontakte-Verzeichnis aktualisieren oder Namen pruefen.")
                    .font(.caption)
                    .foregroundStyle(MykColor.muted)
            }
        } header: {
            Text("Kunde")
        }
    }

    private var springenSektion: some View {
        Section {
            if let url = project.driveURL {
                Link(destination: url) {
                    Label("Drive-Ordner oeffnen", systemImage: "folder.fill")
                }
            }
            ForEach(shortcuts) { shortcut in
                if let url = shortcut.url {
                    Link(destination: url) {
                        Label(shortcut.label, systemImage: "arrow.turn.down.right")
                    }
                }
            }
        } header: {
            Text("Springen")
        } footer: {
            Text("Der Satellit dirigiert, er rendert nicht - Werkzeichnungen und Angebote liegen im Drive-Ordner.")
        }
    }

    private var zeitleisteSektion: some View {
        Section {
            if zeitleiste.isEmpty {
                Text("Noch keine iPhone-Spuren zu diesem Projekt.")
                    .font(.caption)
                    .foregroundStyle(MykColor.muted)
            } else {
                ForEach(zeitleiste.prefix(15)) { eintrag in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: eintrag.symbol)
                            .font(.caption)
                            .foregroundStyle(MykColor.brand)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(eintrag.text).font(.caption).lineLimit(2)
                            Text(eintrag.datum.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(MykColor.muted)
                        }
                    }
                }
            }
        } header: {
            Text("Zeitleiste (lokal)")
        } footer: {
            Text("Alles, was du mit dem iPhone an diesem Projekt getan hast - Fotos, Maengel, Vertraege, Scans, Anfragen, Postbox.")
        }
    }

    private var unterlagenSektion: some View {
        Section {
            ForEach(anleitungen) { anleitung in
                Button {
                    vorschauURL = anleitungenStore.dateiURL(fuer: anleitung)
                } label: {
                    Label(anleitung.anzeigeName, systemImage: "book.closed.fill")
                }
                .foregroundStyle(MykColor.ink)
            }
            ForEach(raumscans) { scan in
                Button {
                    vorschauURL = roomPlanStore.dateiURL(fuer: scan)
                } label: {
                    Label("Raumscan \(scan.aufgenommenAm.formatted(date: .abbreviated, time: .omitted))", systemImage: "cube.transparent")
                }
                .foregroundStyle(MykColor.ink)
            }
        } header: {
            Text("Unterlagen auf dem Geraet")
        }
    }

    private var standortSektion: some View {
        Section {
            if let gemerkterStandort {
                HStack {
                    Label("Gemerkt seit \(gemerkterStandort.gespeichertAm.formatted(date: .abbreviated, time: .omitted))", systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(MykColor.ok)
                    Spacer()
                    Button("Vergessen") {
                        try? standortStore.vergessen(gemerkterStandort.id)
                        geofenceWaechter.aktualisiereRegionen()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MykColor.crit)
                }
            } else if merktGerade {
                ProgressView("Standort wird ermittelt...").font(.caption)
            } else {
                Button {
                    standortMerken()
                } label: {
                    Label("Diesen Ort fuer \(project.title) merken", systemImage: "mappin.and.ellipse")
                }
            }
            if let standortFehler {
                Text(standortFehler).font(.caption2).foregroundStyle(MykColor.crit)
            }
        } header: {
            Text("Standort-Waechter")
        }
    }

    private var hatSchiffsdaten: Bool {
        project.volumen != nil || project.letztesAngebot != nil
            || (project.warenkorb?.isEmpty == false)
    }

    @ViewBuilder
    private var schiffsdatenSektion: some View {
        if hatSchiffsdaten {
            Section {
                if let volumen = project.volumenText {
                    HStack {
                        Label("Volumen", systemImage: "eurosign.circle")
                        Spacer()
                        Text(volumen).foregroundStyle(MykColor.ink).font(.callout.weight(.semibold))
                    }
                }
                if let angebot = project.letztesAngebot {
                    HStack(alignment: .top) {
                        Label("Letztes Angebot", systemImage: "doc.text")
                        Spacer()
                        Text(angebot).foregroundStyle(MykColor.ink).multilineTextAlignment(.trailing)
                    }
                }
            } header: {
                Text("Vom Mothership")
            }
            if let warenkorb = project.warenkorb, !warenkorb.isEmpty {
                Section {
                    ForEach(warenkorb, id: \.self) { position in
                        DisclosureGroup {
                            if let artikelnummer = position.artikelnummer, !artikelnummer.isEmpty {
                                zeile("Artikelnummer", artikelnummer)
                            }
                            if let menge = position.menge { zeile("Menge", "\(menge)") }
                            if let preis = position.einzelpreis {
                                zeile("Einzelpreis", "\(Int(preis.rounded())) EUR")
                            }
                            if let kategorie = position.kategorie, !kategorie.isEmpty {
                                zeile("Kategorie", kategorie)
                            }
                        } label: {
                            HStack {
                                Label(position.name, systemImage: "shippingbox")
                                Spacer()
                                if let unter = position.untertitel {
                                    Text(unter).font(.caption).foregroundStyle(MykColor.muted)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Warenkorb (\(warenkorb.count))")
                } footer: {
                    Text("Geraete und Artikel aus dem Projekt-Warenkorb. Antippen zeigt Details.")
                }
            }
        } else {
            Section {
                Label("Volumen / Budget", systemImage: "eurosign.circle")
                Label("Letztes Angebot / AB", systemImage: "doc.text")
                Label("Geraeteliste aus dem Warenkorb", systemImage: "cart")
            } header: {
                Text("Kommt vom Mothership")
            } footer: {
                Text("Diese Daten leben in Airtable, Drive und WorkBasket. Sie erscheinen hier automatisch, sobald das Schiff sie in den Registry-Schnappschuss exportiert (Format: docs/23) - bis dahin ehrlich leer statt geraten.")
            }
            .foregroundStyle(MykColor.muted)
        }
    }

    private func zeile(_ titel: String, _ wert: String) -> some View {
        HStack {
            Text(titel).font(.caption).foregroundStyle(MykColor.muted)
            Spacer()
            Text(wert).font(.caption)
        }
    }

    private func standortMerken() {
        merktGerade = true
        standortFehler = nil
        Task {
            defer { merktGerade = false }
            guard let koordinate = await ortsSensor.hole() else {
                standortFehler = "Standort nicht ermittelbar - Berechtigung erteilt?"
                return
            }
            do {
                try standortStore.merken(ProjektStandort(
                    projectNumber: project.projectNumber,
                    projectTitel: project.title,
                    breitengrad: koordinate.latitude,
                    laengengrad: koordinate.longitude
                ))
                geofenceWaechter.aktualisiereRegionen()
            } catch {
                standortFehler = Fehlertext.deutsch(error)
            }
        }
    }
}

#Preview {
    let standortStore = ProjektStandortStore()
    let aufenthaltStore = StandortAufenthaltStore()
    ProjektInfoView(
        project: Project(projectNumber: "2026-015", title: "Schmidt", kind: "kitchen", customerNumber: "K-001", driveFolderID: ""),
        shortcuts: [],
        pulsText: "vor 2 Tg",
        store: ProjectStore(),
        feldFotoStore: FeldFotoStore(),
        postbox: PostboxStore(),
        standortStore: standortStore,
        geofenceWaechter: GeofenceWaechter(standortStore: standortStore, aufenthaltStore: aufenthaltStore)
    )
}
