import SwiftUI
import MykilosDesign
import MykilosKit
import MykilosServices

// MARK: - ProjectNumberBindingSection
// mykilOS 8, Block A (Erweiterung, Johannes-Entscheidung 2026-06-30): solange Artikel-
// `Projekte` kein `Projektnummer`-Feld hat, zeigt diese Sektion automatisch erkannte
// Bindungs-Kandidaten (exakter Titel-Match Geschäftsprojekt ↔ Mastermind-Routing) — erst
// nach Bestätigung gilt eine Bindung (Karte→Bestätigung→Audit, ProjectNumberBindingStore).
// Leer + unsichtbar, sobald keine Kandidaten mehr offen sind (kein Leerzustand-Rauschen).
struct ProjectNumberBindingSection: View {
    @Environment(AppState.self) private var appState
    @State private var confirmingID: String?
    @State private var errorMessage: String?

    private var candidates: [ProjectNumberBindingCandidate] {
        appState.projectNumberBindingCandidates()
    }

    var body: some View {
        if !candidates.isEmpty {
            VStack(alignment: .leading, spacing: MykSpace.s3) {
                HStack {
                    Text("Projektnummer-Bindungsvorschläge")
                        .font(.mykMono(11))
                        .foregroundStyle(MykColor.ink.color)
                    Spacer()
                    Text("\(candidates.count)")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                }
                Text("Geschäftsprojekt ohne Projektnummer-Feld, per exaktem Titel-Match einem Routing-Projekt zugeordnet. Erst nach Bestätigung gültig — rein lokal, ändert nie die Artikel-Projektliste.")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)

                ForEach(candidates) { candidate in
                    candidateRow(candidate)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.critical.color)
                }
            }
            .padding(MykSpace.s4)
            .background(MykColor.paper2.color)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: MykRadius.md)
                    .stroke(MykColor.tasks.color.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private func candidateRow(_ candidate: ProjectNumberBindingCandidate) -> some View {
        HStack(spacing: MykSpace.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.businessProjektname)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.ink.color)
                Text("→ \(candidate.projectNumber) · \(candidate.routingTitle)")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            Button {
                confirm(candidate)
            } label: {
                if confirmingID == candidate.id {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Bestätigen")
                        .font(.mykMono(9))
                }
            }
            .buttonStyle(.bordered)
            .disabled(confirmingID != nil)
        }
        .padding(.vertical, MykSpace.s2)
    }

    private func confirm(_ candidate: ProjectNumberBindingCandidate) {
        confirmingID = candidate.id
        errorMessage = nil
        do {
            try appState.confirmProjectNumberBinding(candidate)
        } catch {
            errorMessage = "Bindung fehlgeschlagen: \(error.localizedDescription)"
        }
        confirmingID = nil
    }
}
