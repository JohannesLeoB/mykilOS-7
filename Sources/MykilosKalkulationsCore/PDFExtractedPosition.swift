import Foundation

// MARK: - PDFExtractedPosition (Lern-Loop · lokaler Anker-Kandidat)
//
// Eine aus einem Angebots-PDF herausgelöste Position, LOKAL als Preis-Anker-
// KANDIDAT gespeichert (learning.sqlite). Wird erst durch eine menschliche
// Freigabe (`ReviewAction .releaseAsActiveAnchor`) zu einem aktiven Anker —
// nichts fließt ohne Bestätigung in eine Schätzung ein. Additiv zum bestehenden
// Airtable-/Seed-Anker-Pfad, kein externer Write.
//
// `netPrice` = Netto-EINZELpreis (E.P.), passend zur Anker-Semantik
// (`CandidateReleaseDecision.priceNetGuess`). `id` identifiziert die Position
// eindeutig (Datei + Seite + Index) → ein erneuter Import derselben Position
// erhöht nichts, sondern wird übersprungen (Dedup).
public struct PDFExtractedPosition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let sourceFile: String
    public let pageNumber: Int
    public let title: String
    public let componentType: ComponentType
    public let netPrice: Decimal
    public let unit: String
    public let quantity: Double
    public let confidence: Double
    public let extractedAt: Date

    public init(id: String, sourceFile: String, pageNumber: Int, title: String,
                componentType: ComponentType, netPrice: Decimal, unit: String,
                quantity: Double, confidence: Double, extractedAt: Date) {
        self.id = id
        self.sourceFile = sourceFile
        self.pageNumber = pageNumber
        self.title = title
        self.componentType = componentType
        self.netPrice = netPrice
        self.unit = unit
        self.quantity = quantity
        self.confidence = confidence
        self.extractedAt = extractedAt
    }
}

public extension ComponentType {
    /// Abbildung auf die Kalkulations-Anker-Klasse (`CalculationComponentClass`) —
    /// nur INNERHALB derselben Klasse sind Preise vergleichbar.
    var calculationClass: CalculationComponentClass {
        switch self {
        case .baseCabinetRun:   .kitchenRun
        case .island:           .island
        case .tallCabinetBlock: .tallCabinetBlock
        case .wallCabinets:     .baseUnit
        case .stoneCountertop, .worktopScope: .worktopSurface
        case .applianceScope:   .applianceHandling
        case .drawerAddon:      .baseUnit
        case .delivery, .installation, .projectLogistics: .logistics
        case .aggregateKitchen: .aggregateKitchen
        case .other:            .unknownReview
        }
    }
}
