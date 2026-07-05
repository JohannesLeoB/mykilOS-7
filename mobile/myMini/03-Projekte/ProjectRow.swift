import CoreLocation
import SwiftUI

/// Eine Zeile in der Projektliste. Klick expandiert Deep-Links — der
/// Satellit dirigiert, er rendert nicht (Container-vs-Dirigent-Doktrin).
struct ProjectRow: View {
    let project: Project
    let shortcuts: [DriveShortcut]
    let standortStore: ProjektStandortStore
    let geofenceWaechter: GeofenceWaechter
    @State private var expanded = false
    @State private var merktGerade = false
    @State private var standortFehler: String?
    @State private var ortsSensor = EinmaligerOrtsSensor()

    private var kindColor: Color {
        project.kind == "studioInternal" ? MykColor.plum : MykColor.ocker
    }

    private var gemerkterStandort: ProjektStandort? {
        standortStore.orte.first { $0.projectNumber == project.projectNumber }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 11) {
                    Circle().fill(kindColor).frame(width: 9, height: 9)
                    Text(project.title)
                        .font(.system(.callout, design: .default).weight(.semibold))
                        .foregroundStyle(MykColor.ink)
                    Spacer()
                    Text(project.projectNumber)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(MykColor.muted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let url = project.driveURL {
                        Link(destination: url) {
                            Label("Drive-Ordner", systemImage: "folder.fill")
                                .font(.footnote.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(MykColor.drive)
                    }
                    ForEach(shortcuts) { shortcut in
                        if let url = shortcut.url {
                            Link(shortcut.label, destination: url)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(MykColor.drive)
                        }
                    }
                    if project.title == "Schmidt" {
                        Text("Tür-Briefing · live erhoben 03.07. — Achtung: Mail-Anker 'Schmidt' liefert Homonyme, nur IDs trauen.")
                            .font(.caption2)
                            .foregroundStyle(MykColor.muted)
                    }
                    if geofenceWaechter.aktiv {
                        standortZeile
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .background(MykColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MykColor.line))
    }

    @ViewBuilder
    private var standortZeile: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let gemerkterStandort {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill").foregroundStyle(MykColor.ok)
                    Text("Standort gemerkt seit \(gemerkterStandort.gespeichertAm.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(MykColor.muted)
                    Spacer()
                    Button("Vergessen") {
                        try? standortStore.vergessen(gemerkterStandort.id)
                        geofenceWaechter.aktualisiereRegionen()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MykColor.crit)
                }
            } else if merktGerade {
                ProgressView("Standort wird ermittelt…").font(.caption)
            } else {
                Button {
                    merken()
                } label: {
                    Label("Diesen Ort für \(project.title) merken", systemImage: "mappin.and.ellipse")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(MykColor.brand)
            }
            if let standortFehler {
                Text(standortFehler).font(.caption2).foregroundStyle(MykColor.crit)
            }
        }
    }

    private func merken() {
        merktGerade = true
        standortFehler = nil
        Task {
            defer { merktGerade = false }
            guard let koordinate = await ortsSensor.hole() else {
                standortFehler = "Standort nicht ermittelbar — Berechtigung erteilt?"
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
