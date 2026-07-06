import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - FileDropMarkerPicker
// Ordner-Schema-Editor-Plan, Abschnitt "Mail-Anhang → Marker → Unterordner": ein Marker
// (AB/Rechnung/Zeichnung/…) schlägt den Ziel-Ordner vor (Schaltschrank-Route über OrdnerSlot)
// und tagt das Dokument sichtbar. Passt der vorgeschlagene Ordnername zu einem bereits
// geladenen Ordner (Wurzel oder aktuell durchsuchte Ebene), wird er über `onResolvedTarget`
// direkt übernommen — sonst zeigt die Zeile nur den Namen als Hinweis. Die Ablage selbst bleibt
// in jedem Fall bestätigungspflichtig (kein Auto-Move); dieser Picker setzt nur das Ziel vor.
// Ausgelagert aus FileDropCardView.swift (Datei-Längen-Limit).
struct FileDropMarkerPicker: View {
    let konnektoren: [OrdnerSlot: OrdnerKonnektor]
    let markerRoutes: MailMarkerRouteRegistry
    let rootFolder: DriveFolderChoice?
    let browseChildren: [DriveFolderChoice]
    @Binding var selectedMarker: MailAnhangMarker?
    let onResolvedTarget: (DriveFolderChoice) -> Void

    var body: some View {
        if konnektoren.isEmpty == false {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "tag").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
                Text("Marker").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                ForEach(MailAnhangMarker.allCases) { marker in
                    Button { waehleMarker(marker) } label: {
                        Text(marker.label)
                            .font(.mykMono(9.5))
                            .foregroundStyle(selectedMarker == marker ? MykColor.paper.color : MykColor.drive.color)
                            .padding(.horizontal, MykSpace.s2).padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: MykRadius.sm)
                                    .fill(selectedMarker == marker ? MykColor.drive.color : Color.clear)
                                    .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.drive.color, lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
                if let marker = selectedMarker, let vorschlag = vorschlagsOrdnername(fuer: marker) {
                    Text("→ \(vorschlag)").font(.mykMono(9)).foregroundStyle(MykColor.muted.color).lineLimit(1)
                }
                Spacer()
            }
        }
    }

    private func vorschlagsOrdnername(fuer marker: MailAnhangMarker) -> String? {
        guard let route = markerRoutes.route(fuer: marker) else { return nil }
        return konnektoren[route.ziel]?.ordnername
    }

    private func waehleMarker(_ marker: MailAnhangMarker) {
        selectedMarker = (selectedMarker == marker) ? nil : marker   // erneutes Tippen hebt die Markierung auf
        guard selectedMarker == marker, let vorschlag = vorschlagsOrdnername(fuer: marker) else { return }
        if let treffer = browseChildren.first(where: { $0.name.localizedCaseInsensitiveCompare(vorschlag) == .orderedSame }) {
            onResolvedTarget(treffer)
        } else if let root = rootFolder, root.name.localizedCaseInsensitiveCompare(vorschlag) == .orderedSame {
            onResolvedTarget(root)
        }
        // Kein geladener Treffer? Bewusst kein Auto-Navigate über mehrere Ebenen — der Vorschlags-
        // text bleibt sichtbar, der Nutzer navigiert selbst über den Ziel-Picker dorthin.
    }
}
