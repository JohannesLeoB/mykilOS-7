import Foundation

// MARK: - FolderNode / FolderSchema
// mykilOS 8, Block C (S2): das Projekt-Ordnerschema als VERSIONIERTE DATEN-Definition,
// nicht hartkodierte Strings (HANDOFF_PROVISIONING_NOMENKLATUR §3). Provisioning (Block D)
// liest das aktive Schema; Re-Schematisierung = neue Version anlegen, Konnektoren neu mappen.
public struct FolderNode: Codable, Hashable, Sendable, Identifiable {
    // Stabile ID, UNABHÄNGIG vom Namen (Namen sind Referenzen, keine Primärschlüssel —
    // CLAUDE.md). Wichtig für den Admin-Editor: bindet man ein TextField direkt an `name`,
    // würde eine ID = name bei JEDEM Tastendruck die SwiftUI-Identität wechseln und dem
    // Feld den Fokus rauben.
    public let id: UUID
    public var name: String
    public var children: [FolderNode]

    public init(id: UUID = UUID(), _ name: String, children: [FolderNode] = []) {
        self.id = id
        self.name = name
        self.children = children
    }
}

public struct FolderSchema: Codable, Hashable, Sendable {
    public var version: Int
    /// Template des Wurzelordner-Namens (gefüllt aus Projektnummer/Kunde/STR-Nr beim Anlegen).
    public var rootTemplate: String
    public var children: [FolderNode]
    /// Dateien, die in den Wurzelordner aus der Vorlage mitkopiert werden (Abnahmeprotokoll).
    public var rootDateien: [String]

    public init(version: Int, rootTemplate: String, children: [FolderNode], rootDateien: [String]) {
        self.version = version
        self.rootTemplate = rootTemplate
        self.children = children
        self.rootDateien = rootDateien
    }

    /// FolderSchema v1 — exakt aus `_BEISPIELORDNER` (filesystem-verifiziert,
    /// HANDOFF_PROVISIONING_NOMENKLATUR §3). Default, bis ein neues Schema angelegt wird.
    public static let v1 = FolderSchema(
        version: 1,
        rootTemplate: "<JJJJ_NNN_Kunde_STR-Nr>",
        children: [
            FolderNode("01 INFOS", children: [
                FolderNode("01 Pläne"),
                FolderNode("02 Fotos Bestand"),
                FolderNode("03 Recherche | Zubehör"),
                FolderNode("04 ausgehende Angebote"),
                FolderNode("05 eingehende Angebote"),
                FolderNode("06 Fotos Baustelle"),
                FolderNode("07 Fragebogen"),
                FolderNode("08 Werkszeichnung"),
                FolderNode("09 Fotos Mängel"),
            ]),
            FolderNode("02 CAD", children: [
                FolderNode("VectorWorks"),
            ]),
            FolderNode("03 PRÄSENTATION", children: [
                FolderNode("Moodboards"),
                FolderNode("PDF"),
                FolderNode("Renderings"),
                FolderNode("Vorplanung | Screenshots"),
            ]),
        ],
        rootDateien: ["MYKILOS_Abnahmeprotokoll BLANKO.pdf"]
    )

    /// Alle Ordnerpfade (relativ zum Wurzelordner), tiefen-zuerst — für Provisioning + Tests.
    public func allePfade() -> [String] {
        var pfade: [String] = []
        func walk(_ node: FolderNode, prefix: String) {
            let pfad = prefix.isEmpty ? node.name : prefix + "/" + node.name
            pfade.append(pfad)
            for child in node.children { walk(child, prefix: pfad) }
        }
        for child in children { walk(child, prefix: "") }
        return pfade
    }
}

// MARK: - OrdnerSlot / OrdnerKonnektor
// Logischer Slot → aktueller Ordnername (HANDOFF_PROVISIONING_NOMENKLATUR §10). Code
// referenziert NUR die Slot-ID; ändert sich ein Ordnername/-ort, wird nur der Konnektor
// aktualisiert (+ Schema-Version), alle Lese-/Schreibpfade folgen automatisch.
public enum OrdnerSlot: String, Codable, Sendable, CaseIterable {
    case infos
    case angeboteAusgehend
    case angeboteEingehend
    case fragebogen
    case praesentationPDF
    case cad
}

public struct OrdnerKonnektor: Codable, Hashable, Sendable, Identifiable {
    public var id: String { slot.rawValue }
    public var slot: OrdnerSlot
    public var ordnername: String     // aktueller realer Ordnername
    public var relativerPfad: String  // relativ zum Projekt-Wurzelordner
    public var schemaVersion: Int

    public init(slot: OrdnerSlot, ordnername: String, relativerPfad: String, schemaVersion: Int) {
        self.slot = slot
        self.ordnername = ordnername
        self.relativerPfad = relativerPfad
        self.schemaVersion = schemaVersion
    }

    /// Default-Konnektoren für FolderSchema v1 (mappen auf den dokumentierten Baum).
    public static let v1Defaults: [OrdnerKonnektor] = [
        OrdnerKonnektor(slot: .infos,             ordnername: "01 INFOS",              relativerPfad: "01 INFOS", schemaVersion: 1),
        OrdnerKonnektor(slot: .angeboteAusgehend, ordnername: "04 ausgehende Angebote", relativerPfad: "01 INFOS/04 ausgehende Angebote", schemaVersion: 1),
        OrdnerKonnektor(slot: .angeboteEingehend, ordnername: "05 eingehende Angebote", relativerPfad: "01 INFOS/05 eingehende Angebote", schemaVersion: 1),
        OrdnerKonnektor(slot: .fragebogen,        ordnername: "07 Fragebogen",          relativerPfad: "01 INFOS/07 Fragebogen", schemaVersion: 1),
        OrdnerKonnektor(slot: .praesentationPDF,  ordnername: "PDF",                    relativerPfad: "03 PRÄSENTATION/PDF", schemaVersion: 1),
        OrdnerKonnektor(slot: .cad,               ordnername: "VectorWorks",            relativerPfad: "02 CAD/VectorWorks", schemaVersion: 1),
    ]
}
