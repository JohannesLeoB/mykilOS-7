import SwiftUI
import MykilosDesign
import MykilosServices

// MARK: - DriveFolderCategory → Farbe (D3)
//
// Die Widget-/Design-seitige Brücke: ordnet die reine, testbare
// `DriveFolderCategory` (MykilosServices) einer stabilen MykColor-Rolle zu.
// „Farbe ist Sprache": Angebote = Tiefblau (Geld), Zeichnungen = Terrakotta
// (Dateien/Drive), Präsentation = Salbei (Menschen/Blick), Infos = Ocker
// (Aufgaben/Ablage). Bewusst dezent eingesetzt (kleiner Punkt, muted Chip).
public extension DriveFolderCategory {
    var markeColor: Color {
        switch self {
        case .angebote:      MykColor.cash.color
        case .zeichnungen:   MykColor.drive.color
        case .praesentation: MykColor.people.color
        case .infos:         MykColor.tasks.color
        }
    }
}

// MARK: - HerkunftMarke
//
// Kleiner Farbpunkt (Kategorie) + Ordnername als muted Mono-Chip (VERSAL).
// Dezent — die Herkunft ergänzt die Datei, dominiert sie nie. Zeigt nichts,
// wenn kein Ordnername vorliegt (keine Sackgasse, kein leerer Chip).
public struct HerkunftMarke: View {
    public let folderName: String?
    /// `true` in engen Kacheln — nur der Farbpunkt, ohne Text-Chip.
    public var punktNur: Bool = false

    public init(folderName: String?, punktNur: Bool = false) {
        self.folderName = folderName
        self.punktNur = punktNur
    }

    private var category: DriveFolderCategory? {
        DriveFolderCategory.category(forFolderName: folderName)
    }

    // Dezenter Grundton für unbekannte Herkunft (Ordner ohne Schema-Kategorie).
    private var dotColor: Color { category?.markeColor ?? MykColor.faint.color }

    public var body: some View {
        if let name = folderName, name.isEmpty == false {
            HStack(spacing: MykSpace.s2) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                if punktNur == false {
                    Text(name.uppercased())
                        .font(.mykMono(8))
                        .foregroundStyle(MykColor.muted.color)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .help(chipHelp(name))
            .accessibilityLabel("Herkunft: \(name)")
        }
    }

    private func chipHelp(_ name: String) -> String {
        if let category { return "\(name) · \(category.chipLabel)" }
        return name
    }
}
