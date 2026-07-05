import SwiftUI

/// Phase 2 der Fusion — der gefuehrte Auftrag. Aus 20 einzelnen Werkzeugen
/// wird EINE Erzaehlung pro Projekt: Kunde -> Aufmass -> Erfassen -> Entwurf
/// -> Kalkulation/Angebot -> Vertrag -> Nachbetreuung. Jede Station zeigt
/// ihren Stand aus echten lokalen Daten und fuehrt mit einem Tipp zum
/// passenden Werkzeug. Der rote Faden durchs ganze Cockpit.
struct AuftragsReiseView: View {
    let project: Project
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    @State private var roomPlanStore = RoomPlanStore()
    @State private var briefStore = KreativBriefStore()
    @State private var vertragsRegister = VertragsRegister()
    @State private var partnerStore = ServicePartnerStore()
    @State private var abnahme = AbnahmeprotokollStore()
    @State private var kontakteStore = KontakteStore()
    @State private var berichtURL: URL?
    @State private var berichtFehler: String?

    private var fotos: Int { feldFotoStore.fotos.filter { $0.projectNumber == project.projectNumber }.count }
    private var scans: Int { roomPlanStore.aufnahmen.filter { $0.projectNumber == project.projectNumber }.count }
    private var briefs: Int { briefStore.briefs.filter { $0.projectNumber == project.projectNumber }.count }
    private var vertraege: Int { vertragsRegister.vertraege.filter { $0.projectNumber == project.projectNumber }.count }
    private var anfragen: Int { partnerStore.anfragen.filter { $0.projectTitel == project.title }.count }
    private var maengel: Int { abnahme.eintraege.filter { $0.projectNumber == project.projectNumber }.count }
    private var hatKunde: Bool {
        let t = project.title.lowercased()
        return kontakteStore.kontakte.contains { $0.name.lowercased().contains(t) || t.contains($0.name.lowercased()) }
    }

    private var erledigt: Int {
        [hatKunde, scans > 0 || fotos > 0, briefs > 0,
         project.volumen != nil || project.letztesAngebot != nil,
         vertraege > 0, anfragen > 0 || maengel > 0].filter { $0 }.count
    }
    private let stationenGesamt = 6

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title).font(.title3.weight(.bold))
                    ProgressView(value: Double(erledigt), total: Double(stationenGesamt))
                        .tint(MykColor.brand)
                    Text("\(erledigt) von \(stationenGesamt) Stationen begonnen")
                        .font(.caption).foregroundStyle(MykColor.muted)
                }
            }

            NavigationLink {
                KontakteVerzeichnisView()
            } label: {
                station("person.crop.circle", "Kunde", hatKunde ? "Im Verzeichnis" : "Noch nicht zugeordnet", hatKunde)
            }

            NavigationLink {
                RoomPlanCaptureScreen(store: store, roomPlanStore: roomPlanStore)
            } label: {
                station("cube.transparent", "Aufmass", scans > 0 ? "\(scans) Raumscan(s)" : "Noch kein Scan", scans > 0)
            }

            NavigationLink {
                FotoBemassungView(store: store, feldFotoStore: feldFotoStore)
            } label: {
                station("camera.viewfinder", "Erfassen & Bemassen", fotos > 0 ? "\(fotos) Feld-Foto(s)" : "Noch keine Fotos", fotos > 0)
            }

            NavigationLink {
                KreativStudioView(store: store, feldFotoStore: feldFotoStore)
            } label: {
                station("wand.and.stars", "Entwurf", briefs > 0 ? "\(briefs) Render-Brief(s)" : "Noch kein Entwurf", briefs > 0)
            }

            Section {
                station("eurosign.circle",
                        "Kalkulation & Angebot",
                        kalkulationStatus,
                        project.volumen != nil || project.letztesAngebot != nil)
            } footer: {
                Text("Kommt vom Mothership (Volumen/Angebot) - erscheint hier, sobald das Schiff es liefert.")
            }

            NavigationLink {
                VertragSignierenView(store: store)
            } label: {
                station("signature", "Vertrag", vertraege > 0 ? "\(vertraege) unterzeichnet" : "Noch nicht unterschrieben", vertraege > 0)
            }

            NavigationLink {
                ServiceAnfrageView(store: store, feldFotoStore: feldFotoStore)
            } label: {
                station("wrench.adjustable", "Nachbetreuung",
                        (anfragen + maengel) > 0 ? "\(anfragen) Anfragen, \(maengel) Maengel" : "Nichts offen",
                        anfragen + maengel > 0)
            }

            Section {
                if let berichtURL {
                    ShareLink(item: berichtURL) {
                        Label("Feld-Bericht ans Schiff senden", systemImage: "paperplane.fill")
                            .foregroundStyle(MykColor.brand)
                    }
                } else {
                    Button {
                        berichtBauen()
                    } label: {
                        Label("Feld-Bericht erstellen", systemImage: "doc.badge.arrow.up")
                    }
                }
                if let berichtFehler {
                    Text(berichtFehler).font(.caption).foregroundStyle(MykColor.crit)
                }
            } header: {
                Text("Rueckkanal")
            } footer: {
                Text("Buendelt alles Erfasste (Fotos, Scans, Vertraege, Anfragen, Maengel) als JSON und schickt es per AirDrop an den Mac oder in den Projekt-Drive - das Schiff liest es in die Projektakte ein (Format: docs/24).")
            }
        }
        .navigationTitle("Gefuehrter Auftrag")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func berichtBauen() {
        berichtFehler = nil
        let pn = project.projectNumber
        let bericht = SatellitenBericht(
            projectNumber: pn,
            projectTitel: project.title,
            erstelltAm: Date(),
            fotos: feldFotoStore.fotos.filter { $0.projectNumber == pn }.map {
                .init(dateiname: $0.dateiname, ziel: $0.kanonZiel.titel, aufgenommenAm: $0.aufgenommenAm,
                      breitengrad: $0.breitengrad, laengengrad: $0.laengengrad,
                      foerderrelevant: $0.foerderrelevant, inDrive: $0.syncedAt != nil)
            },
            scans: roomPlanStore.aufnahmen.filter { $0.projectNumber == pn }.map {
                .init(dateiname: $0.dateiname, aufgenommenAm: $0.aufgenommenAm)
            },
            vertraege: vertragsRegister.vertraege.filter { $0.projectNumber == pn }.map {
                .init(vertragsName: $0.vertragsName, unterzeichner: $0.unterzeichner,
                      unterschriebenAm: $0.unterschriebenAm, sha256: $0.sha256)
            },
            anfragen: partnerStore.anfragen.filter { $0.projectTitel == project.title }.map {
                .init(partnerName: $0.partnerName, geraet: $0.geraet, gesendetAm: $0.gesendetAm)
            },
            maengel: abnahme.eintraege.filter { $0.projectNumber == pn }.map {
                .init(text: $0.text, erfasstAm: $0.erfasstAm)
            })
        do {
            berichtURL = try bericht.alsDatei()
        } catch {
            berichtFehler = Fehlertext.deutsch(error)
        }
    }

    private var kalkulationStatus: String {
        var teile: [String] = []
        if let v = project.volumenText { teile.append(v) }
        if project.letztesAngebot != nil { teile.append("Angebot da") }
        return teile.isEmpty ? "Wartet aufs Schiff" : teile.joined(separator: " - ")
    }

    private func station(_ icon: String, _ titel: String, _ status: String, _ erledigt: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: erledigt ? "checkmark.circle.fill" : icon)
                .font(.title3)
                .foregroundStyle(erledigt ? MykColor.ok : MykColor.brand)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.callout.weight(.semibold)).foregroundStyle(MykColor.ink)
                Text(status).font(.caption).foregroundStyle(MykColor.muted)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuftragsReiseView(
            project: Project(projectNumber: "2026-015", title: "Schmidt", kind: "kitchen", customerNumber: "K-001", driveFolderID: ""),
            store: ProjectStore(),
            feldFotoStore: FeldFotoStore())
    }
}
