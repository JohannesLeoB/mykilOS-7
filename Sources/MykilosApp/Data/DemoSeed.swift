import Foundation
import MykilosKit
import MykilosServices

// MARK: - DemoSeed
// Seeded Demo-Daten für Entwicklung und erste Inbetriebnahme.
// Läuft nur wenn die Registry leer ist (ColdStart-safe).
public enum DemoSeed {
    public static func inject(into registry: CachedProjectRegistry) throws {
        let customers: [Customer] = [
            Customer(customerNumber: "K-1001", name: "Familie Meyer",
                     airtableRecordID: "rec001"),
            Customer(customerNumber: "K-1002", name: "Loft GmbH",
                     airtableRecordID: "rec002"),
            Customer(customerNumber: "K-1003", name: "Praxis Sonnenberg",
                     airtableRecordID: "rec003"),
            Customer(customerNumber: "K-1004", name: "Studio Bergmann",
                     airtableRecordID: "rec004"),
        ]

        let projects: [Project] = [
            Project(projectNumber: "ME-24",
                    title: "Küche Meyer",
                    kind: .kitchen,
                    customerNumber: "K-1001",
                    links: ProjectLinks(
                        driveFolderID: "1AbC_drive_meyer",
                        driveFolderPath: "Projekte/ME-24 Küche Meyer",
                        clickUpListID: "9012345",
                        calendarQuery: "Meyer",
                        contactsQuery: "Meyer",
                        sevdeskRef: "1001",
                        budget: 48000
                    ),
                    phase: "Ausführungsplanung",
                    airtableRecordID: "recME24",
                    updatedAt: Date()),

            Project(projectNumber: "ME-24-N1",
                    title: "Nachtrag Beleuchtung",
                    kind: .addendum,
                    customerNumber: "K-1001",
                    parentProjectNumber: "ME-24",
                    links: ProjectLinks(driveFolderID: "1AbC_drive_meyer_n1"),
                    phase: "Angebot",
                    airtableRecordID: "recME24N1",
                    updatedAt: Date().addingTimeInterval(-3600)),

            Project(projectNumber: "LO-23",
                    title: "Loft Umbau Mitte",
                    kind: .kitchen,
                    customerNumber: "K-1002",
                    links: ProjectLinks(
                        driveFolderID: "2XyZ_drive_loft",
                        clickUpListID: "9012346",
                        calendarQuery: "Loft",
                        sevdeskRef: "1002",
                        budget: 120000
                    ),
                    phase: "Genehmigungsplanung",
                    airtableRecordID: "recLO23",
                    updatedAt: Date().addingTimeInterval(-86400)),

            Project(projectNumber: "SO-24",
                    title: "Lichtplanung Praxis",
                    kind: .lighting,
                    customerNumber: "K-1003",
                    links: ProjectLinks(driveFolderID: "3LiG_drive_praxis"),
                    phase: "Konzept",
                    airtableRecordID: "recSO24",
                    updatedAt: Date().addingTimeInterval(-172800)),

            Project(projectNumber: "BE-24",
                    title: "Studio Bergmann Küche",
                    kind: .kitchen,
                    customerNumber: "K-1004",
                    links: ProjectLinks(
                        driveFolderID: "4BeR_drive_studio",
                        clickUpListID: "9012347"
                    ),
                    phase: "Entwurf",
                    airtableRecordID: "recBE24",
                    updatedAt: Date().addingTimeInterval(-259200)),

            Project(projectNumber: "ME-23",
                    title: "Bad Meyer",
                    kind: .addendum,
                    customerNumber: "K-1001",
                    links: ProjectLinks(driveFolderID: "1AbC_drive_meyer_bad"),
                    phase: "Abgeschlossen",
                    airtableRecordID: "recME23",
                    updatedAt: Date().addingTimeInterval(-2592000)),
        ]

        try registry.replaceCustomers(customers)
        try registry.replaceProjects(projects)
    }
}
