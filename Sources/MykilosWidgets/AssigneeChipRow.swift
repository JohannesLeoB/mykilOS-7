import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - AssigneeChipRow (ClickUp-Vollintegration, 2026-07-07)
// Zeigt die zugewiesenen Teammitglieder einer ClickUpTask als farbige Kürzel-Chips
// (Jo/Da/Fra/Sen/Jil, TeamRoster). Rein LESEND — spiegelt nur, was ClickUp bereits als
// echten Assignee führt; mykilOS weist hier nichts zu und schreibt nichts. Eine unbekannte
// Member-ID (z. B. ein Gast-Account) rendert einfach nichts — kein Rate-Chip.
public struct AssigneeChipRow: View {
    public let assigneeIDs: [String]
    public init(assigneeIDs: [String]) { self.assigneeIDs = assigneeIDs }

    private var kuerzel: [String] {
        assigneeIDs.compactMap(TeamRoster.kuerzel(fuerClickUpMemberID:))
    }

    public var body: some View {
        if kuerzel.isEmpty == false {
            HStack(spacing: 3) {
                ForEach(kuerzel, id: \.self) { einzelKuerzel in
                    Text(einzelKuerzel.uppercased())
                        .font(.mykMono(8))
                        .foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(MykColor.fuerTeamKuerzel(einzelKuerzel)))
                }
            }
        }
    }
}
