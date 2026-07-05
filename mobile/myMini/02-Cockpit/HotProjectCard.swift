import SwiftUI

/// Eine Kachel in der „Gerade heiß"-Zeile — Springen, nie Rendern
/// (Deep-Link-Matrix: Drive-Ordner öffnet in der nativen Drive-App).
struct HotProjectCard: View {
    let hot: HotProject

    var body: some View {
        Link(destination: hot.project.driveURL ?? URL(string: "https://drive.google.com")!) {
            VStack(alignment: .leading, spacing: 2) {
                Text(hot.project.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MykColor.ink)
                Text(hot.relativeLabel)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(MykColor.brand)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(MykColor.card)
            .overlay(alignment: .leading) {
                Rectangle().fill(MykColor.brand).frame(width: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line)
            )
        }
        .buttonStyle(.plain)
    }
}
