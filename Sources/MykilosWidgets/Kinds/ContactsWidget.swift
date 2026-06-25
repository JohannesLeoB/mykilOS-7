import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - ContactsWidget  
// Menschen. Bauherr, Architektin, Lieferanten. Salbei.
public struct ContactsWidget: View {
    public let projectID: String
    public init(projectID: String) { self.projectID = projectID }

    public var body: some View {
        WidgetContainer(
            kind: .contacts,
            sourceLabel: "KONTAKTE  ·  GOOGLE  ·  SYNCHRON",
            renderState: .content,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack { SourceChip(kind: .contacts); Text("Kontakte").mykWidgetTitle(); Spacer() }
                VStack(spacing: 0) {
                    ForEach(demoContacts, id: \.name) { contact in
                        ContactRow(contact: contact)
                        if contact.name != demoContacts.last?.name {
                            Divider().overlay(MykColor.line.color.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    struct DemoContact { let initials: String; let name: String; let role: String; let color: Color }
    var demoContacts: [DemoContact] {[
        DemoContact(initials: "FM", name: "Familie Meyer",  role: "BAUHERR",    color: MykColor.people.color),
        DemoContact(initials: "SA", name: "Sandra Adler",   role: "ARCHITEKTIN", color: MykColor.cash.color),
        DemoContact(initials: "HT", name: "Holz Thiel",     role: "TISCHLEREI", color: MykColor.drive.color),
    ]}
}

private struct ContactRow: View {
    let contact: ContactsWidget.DemoContact
    var body: some View {
        HStack(spacing: MykSpace.s4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [contact.color, contact.color.opacity(0.7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
                .overlay(Text(contact.initials).font(.mykMono(11)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                Text(contact.role).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            Spacer()
        }
        .padding(.vertical, MykSpace.s3)
    }
}
