import Foundation

// MARK: - Wirbelsäule-Fundament (Welle C, Schritt C1)
//
// Die vier Primitive der generischen Checkout-Pipeline aus dem S10-Blueprint
// (`docs/S10_WIRBELSAEULE.md`): Pick → WorkBasket → CheckoutPort → PortRegistry.
//
// HARTE MODULREGEL: Diese Datei lebt in MykilosKit und importiert AUSSCHLIESSLICH
// Foundation — nie SwiftUI, nie GRDB, nie ein anderes unserer Module. Reine
// Domänen-Wertetypen + Protokolle. Persistenz gehört nach MykilosServices,
// UI nach MykilosApp. (§1)
//
// Dieses Fundament wird in C1 NICHT verdrahtet (kein CartStore, kein GRDB,
// keine UI) — es ist Typmodell + Tests, sonst nichts.

// MARK: - CatalogObjectID

/// Stabiler, unveränderlicher Bezeichner für EIN Katalog-Objekt (Artikel,
/// Kontakt, Bild, Textblock, Dienstleistung, Eingangsangebot-Position, …).
///
/// Rückverfolgbarkeits-Leitlinie (Johannes 2026-07-02, §2/§10): Diese ID wird
/// einmalig vergeben und danach **nie neu zugewiesen, kopiert, gelöscht oder
/// verändert**. Ein `Pick` referenziert nur diese ID → jeder Wert bleibt
/// lückenlos ins Original zurückverfolgbar. Als `let`-gekapselter Wertetyp gibt
/// es keinen Mutations-Pfad.
public struct CatalogObjectID: Hashable, Sendable, Codable, CustomStringConvertible {
    /// Der rohe, unveränderliche Schlüssel des Katalog-Objekts.
    public let raw: String

    public init(_ raw: String) {
        self.raw = raw
    }

    public var description: String { raw }
}

// MARK: - CatalogMatrix

/// Quell-Matrix (Katalog-Herkunft) eines Picks — *woher* das Objekt stammt.
///
/// Bewusst erweiterbar (§2): weitere Matrizen kommen hinzu, ohne dass die
/// generische Pipeline sich ändert. `sonstige` fängt noch nicht modellierte
/// Quellen ab, statt den Typ zu sprengen.
public enum CatalogMatrix: String, Hashable, Sendable, Codable, CaseIterable {
    case kunde
    case projekt
    case artikel
    case material
    case lager
    case bild
    case zeichnung
    case textblock
    case dienstleistung
    case eingangsangebot
    case sonstige
}

// MARK: - InhaltsArt

/// Inhalts-Art eines WorkBaskets — *was* im Korb steckt (§5b). Steuert allein,
/// welche Ports im Checkout erscheinen (Inhalts-Art-Gate, §4).
///
/// Erweiterbar; `gemischt` steht für einen Korb mit mehreren Matrizen zugleich
/// (Kontakt + Artikel + Eingangsangebot + Notiz).
public enum InhaltsArt: String, Hashable, Sendable, Codable, CaseIterable {
    case artikel
    case bilder
    case material
    case zeichnungen
    case textbausteine
    case dokumente
    case gemischt
}

// MARK: - PickSnapshot

/// Leichte Metadaten eines Picks — bleibt bewusst klein (§2). Die echten Bytes
/// (Bild, PDF, vCard) werden erst per `Pick.resolve()` beim Checkout
/// materialisiert; der Snapshot trägt nur Referenz-Metadaten.
public struct PickSnapshot: Hashable, Sendable, Codable {
    /// Menschenlesbare Bezeichnung (Pflichtfeld, sichtbar in der UI).
    public let bezeichnung: String
    /// Menge (Positionen tragen typischerweise 1).
    public let menge: Int
    /// Einkaufspreis netto pro Einheit (optional, falls bekannt).
    public let ekEinzel: Double?
    /// Verkaufspreis netto pro Einheit (optional, falls kalkuliert).
    public let vkEinzel: Double?
    /// Freie Zusatz-Attribute (matrix-spezifisch), ohne den Typ aufzublähen.
    public let attribute: [String: String]

    public init(
        bezeichnung: String,
        menge: Int = 1,
        ekEinzel: Double? = nil,
        vkEinzel: Double? = nil,
        attribute: [String: String] = [:]
    ) {
        self.bezeichnung = bezeichnung
        self.menge = menge
        self.ekEinzel = ekEinzel
        self.vkEinzel = vkEinzel
        self.attribute = attribute
    }
}

// MARK: - PickContent

/// Der aufgelöste, echte Inhalt eines Picks (Ergebnis von `resolve()`).
/// Materialisiert erst beim Checkout, damit Warenkörbe leicht bleiben (§2/§5g).
public enum PickContent: Sendable, Equatable {
    /// Reiner Text (Notiz, Textblock, Fließtext).
    case text(String)
    /// Verweis auf eine lokale/entfernte Datei-URL (kein Binärkopieren).
    case datei(URL)
    /// Rohbytes mit MIME-Typ (Bild, PDF, vCard-Blob).
    case bytes(Data, mimeType: String)
    /// Kontaktkarte als serialisierter String (z. B. vCard-Text).
    case kontaktkarte(String)
    /// Kein materialisierbarer Inhalt (reine Referenz-Position).
    case keiner
}

// MARK: - Pick

/// Typisierter Verweis auf EIN Katalog-Objekt (§1/§2). Trägt die stabile
/// `objektID`, leichte `snapshot`-Metadaten und löst seinen echten Inhalt lazy
/// per `resolve()` auf.
public protocol Pick: Sendable {
    /// Quell-Matrix des referenzierten Objekts.
    var matrix: CatalogMatrix { get }
    /// Stabile, unveränderliche Katalog-ID (Rückverfolgbarkeit).
    var objektID: CatalogObjectID { get }
    /// Leichte Metadaten (Bezeichnung, Menge, EK, VK, Attribute).
    var snapshot: PickSnapshot { get }
    /// Materialisiert den echten Inhalt — erst beim Checkout aufgerufen.
    func resolve() async throws -> PickContent
}

/// Konkreter, konstruier- und testbarer `Pick`: hält seinen aufgelösten Inhalt
/// bereits im Speicher und gibt ihn unverändert aus `resolve()` zurück.
public struct BasicPick: Pick {
    public let matrix: CatalogMatrix
    public let objektID: CatalogObjectID
    public let snapshot: PickSnapshot
    /// Vorab hinterlegter Inhalt; `resolve()` liefert exakt diesen Wert.
    public let inhalt: PickContent

    public init(
        matrix: CatalogMatrix,
        objektID: CatalogObjectID,
        snapshot: PickSnapshot,
        inhalt: PickContent = .keiner
    ) {
        self.matrix = matrix
        self.objektID = objektID
        self.snapshot = snapshot
        self.inhalt = inhalt
    }

    public func resolve() async throws -> PickContent {
        inhalt
    }
}

// MARK: - WorkBasketID

/// Einmalig vergebener, unveränderlicher Bezeichner eines WorkBaskets —
/// nie wiederverwendet (§3/§10). String-gekapselter Wertetyp ohne Mutations-Pfad.
public struct WorkBasketID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let raw: String

    public init(_ raw: String) {
        self.raw = raw
    }

    public var description: String { raw }
}

// MARK: - WorkBasketStatus

/// Lebenszyklus-Status eines Projekt-Warenkorbs (§7).
///
/// State Machine:
/// ```
/// [ kalkulation ]  --bestätigt-->  [ bestaetigt · eingefroren ]
///                                        └─ Fortführung NUR durch
///                                           [ nachtrag(zu:) ] / [ gutschrift(zu:) ]
/// ```
/// `bestaetigt` und alles stromabwärts davon sind eingefroren — unveränderlich.
public enum WorkBasketStatus: Sendable, Equatable {
    /// Live, nicht final — der aktuellste Kalkulationswarenkorb, ändert sich frei.
    case kalkulation
    /// Eingefroren, fest am Projekt — von sevDesk via Eingangs-Postbox bestätigt.
    case bestaetigt
    /// Nachtrag zu einem bestätigten Korb (append-only Kette).
    case nachtrag(zu: WorkBasketID)
    /// Gutschrift zu einem bestätigten Korb (späteres Kapitel, §7).
    case gutschrift(zu: WorkBasketID)

    /// Eingefroren = unveränderlich. Wahr für `bestaetigt` und alles stromabwärts
    /// (Nachtrag/Gutschrift). Nur `kalkulation` ist frei änderbar.
    public var istEingefroren: Bool {
        switch self {
        case .kalkulation:
            return false
        case .bestaetigt, .nachtrag, .gutschrift:
            return true
        }
    }

    /// Reine, testbare Übergangsregel der State Machine (§7).
    ///
    /// Erlaubt sind ausschließlich:
    /// - `kalkulation → bestaetigt` (sevDesk friert den Korb ein),
    /// - `bestaetigt → nachtrag(...)` / `bestaetigt → gutschrift(...)`
    ///   (Fortführung nur über die append-only Kette).
    ///
    /// Alles andere — insbesondere jeder Rückweg aus einem eingefrorenen Zustand
    /// zurück nach `kalkulation` — ist verboten.
    public func darfWechselnZu(_ ziel: WorkBasketStatus) -> Bool {
        switch (self, ziel) {
        case (.kalkulation, .bestaetigt):
            return true
        case (.bestaetigt, .nachtrag), (.bestaetigt, .gutschrift):
            return true
        default:
            return false
        }
    }
}

// MARK: - WorkBasket

/// Der verallgemeinerte Warenkorb (§1/§3): geordnete, versionierte Menge von
/// Picks; trägt Inhalts-Art, Projektbezug und Lebenszyklus-Status.
///
/// Kein Artikel-only-Hardwiring — ein Korb kann gemischte Matrizen tragen.
/// `picks` ist `[any Pick]`, da Pick ein Protokoll mit assoziiertem Verhalten ist.
public struct WorkBasket {
    /// Einmaliger, nie wiederverwendeter Bezeichner.
    public let id: WorkBasketID
    /// Projektbezug im App-Format `JJJJ-NR`.
    public let projektNummer: String
    /// Was im Korb steckt — steuert die verfügbaren Ports (§5b).
    public var inhaltsArt: InhaltsArt
    /// Geordnete Positionen (heterogen erlaubt).
    public var picks: [any Pick]
    /// Append-only Versionierung (§3) — Änderungen erzeugen neue Versionen.
    public var version: Int
    /// Lebenszyklus-Status (§7).
    public var status: WorkBasketStatus
    /// Erstellzeitpunkt.
    public let erstellt: Date

    public init(
        id: WorkBasketID,
        projektNummer: String,
        inhaltsArt: InhaltsArt,
        picks: [any Pick] = [],
        version: Int = 1,
        status: WorkBasketStatus = .kalkulation,
        erstellt: Date = Date()
    ) {
        self.id = id
        self.projektNummer = projektNummer
        self.inhaltsArt = inhaltsArt
        self.picks = picks
        self.version = version
        self.status = status
        self.erstellt = erstellt
    }
}

// MARK: - PortID

/// Bezeichner eines Ports (z. B. "sevdesk", "moodboard", "geraeteliste",
/// "firefly-prompt"). String-gekapselter Wertetyp.
public struct PortID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let raw: String

    public init(_ raw: String) {
        self.raw = raw
    }

    public var description: String { raw }
}

// MARK: - PortZiel

/// CheckoutPort-spezifische Ziel-Konfiguration (§5 Schritt 2, „Versandadresse").
/// Bewusst minimal gehalten: ein `kind` plus freie Parameter — jeder CheckoutPort
/// interpretiert die Parameter selbst.
public struct PortZiel: Hashable, Sendable, Codable {
    /// Art der Zieladresse/Postbox (port-spezifisch, z. B. "postbox", "drive-ordner").
    public let kind: String
    /// Freie Parameter (z. B. Ordner-ID, Template-Name).
    public let parameter: [String: String]

    public init(kind: String, parameter: [String: String] = [:]) {
        self.kind = kind
        self.parameter = parameter
    }
}

// MARK: - CheckoutPreview / CheckoutResult

/// Vorschau eines Checkouts — was rauskommt, bevor es passiert (§5 Schritt 3).
public struct CheckoutPreview: Sendable, Equatable {
    /// Menschenlesbare Zusammenfassung des geplanten Outputs.
    public let zusammenfassung: String
    /// Warnungen (fehlende Pflichtfelder, riskante Ziele, …).
    public let warnungen: [String]

    public init(zusammenfassung: String, warnungen: [String] = []) {
        self.zusammenfassung = zusammenfassung
        self.warnungen = warnungen
    }
}

/// Ergebnis eines ausgeführten Checkouts (§5 Schritt 5).
public struct CheckoutResult: Sendable, Equatable {
    /// Ob der Write/Render/Prompt erfolgreich war.
    public let erfolg: Bool
    /// Optionale Referenz auf den erzeugten Output (Postbox-Record-ID, URL, …).
    public let referenz: String?
    /// Optionale Meldung (Fehlergrund oder Erfolgshinweis).
    public let meldung: String?

    public init(erfolg: Bool, referenz: String? = nil, meldung: String? = nil) {
        self.erfolg = erfolg
        self.referenz = referenz
        self.meldung = meldung
    }
}

// MARK: - CheckoutPort

/// Benannter Ausgang (= CheckoutTarget, §1/§4): nimmt einen WorkBasket und
/// erzeugt Output in eine Ziel-Postbox. Jeder CheckoutPort deklariert selbst, welche
/// Inhalts-Arten er verarbeiten kann (Inhalts-Art-Gate).
public protocol CheckoutPort: Sendable {
    /// Stabiler CheckoutPort-Bezeichner (auch der Schlüssel im Rechte-Gate).
    var id: PortID { get }
    /// Menschenlesbarer Name (CheckoutPort-Liste im Checkout-Sheet).
    var name: String { get }
    /// Welche Inhalts-Arten dieser CheckoutPort verarbeiten kann (§5b/§5d).
    func erlaubteInhaltsArten() -> Set<InhaltsArt>
    /// Vorschau des geplanten Outputs — schreibt nichts.
    func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview
    /// Führt aus: schreibt/rendert/prompted in die Ziel-Postbox.
    func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult
}

// MARK: - PortRightsProviding

/// Liefert die Menge der PortIDs, die ein bestimmter User verwenden darf (§4/§5f).
/// Rechte-Quelle perspektivisch Airtable (D1), lokal gecacht; bis dahin `AllowAllPortRights`.
public protocol PortRightsProviding: Sendable {
    func erlaubtePorts(userID: String) -> Set<PortID>
}

/// Übergangs-Implementierung: erlaubt jedem User jeden CheckoutPort. Der echte
/// Admin-verteilte Rechte-Filter aus Airtable kommt in D1 (§9 Rechte-Schicht).
///
/// Umsetzung: Das PortRegistry kennt seine registrierten Ports; dieser Provider
/// gibt schlicht deren komplette ID-Menge zurück, sodass die Schnittmenge
/// „User-Recht ∩ Inhalts-Art" den Filter nie einschränkt.
public struct AllowAllPortRights: PortRightsProviding {
    /// Die ID-Menge, die als „alles erlaubt" zurückgegeben wird.
    private let alle: Set<PortID>

    /// - Parameter alleBekanntenPorts: alle PortIDs, die als erlaubt gelten sollen.
    public init(alleBekanntenPorts: Set<PortID>) {
        self.alle = alleBekanntenPorts
    }

    public func erlaubtePorts(userID: String) -> Set<PortID> {
        alle
    }
}

// MARK: - PortRegistry

/// Hält die registrierten Ports und liefert die im Checkout verfügbaren:
/// **Inhalts-Art-Gate ∩ User-Recht** (§4/§5f).
///
/// Ein CheckoutPort erscheint genau dann, wenn
/// 1. seine `erlaubteInhaltsArten()` die gefragte `inhaltsArt` enthält **und**
/// 2. seine `id` in der vom Rechte-Provider erlaubten Menge des Users liegt.
public struct PortRegistry {
    /// Registrierte Ports (Reihenfolge = Reihenfolge der Registrierung).
    public private(set) var ports: [any CheckoutPort]

    public init(ports: [any CheckoutPort] = []) {
        self.ports = ports
    }

    /// Registriert einen weiteren CheckoutPort. Neue Ports erscheinen automatisch in der
    /// Checkout-Liste — kein neues UI je CheckoutPort (§4).
    public mutating func registriere(_ port: any CheckoutPort) {
        ports.append(port)
    }

    /// Die IDs aller registrierten Ports (praktisch für `AllowAllPortRights`).
    public var alleBekanntenPortIDs: Set<PortID> {
        Set(ports.map(\.id))
    }

    /// Liefert die verfügbaren Ports = Inhalts-Art-Gate ∩ User-Recht.
    public func ports(
        fuer inhaltsArt: InhaltsArt,
        userID: String,
        rechte: PortRightsProviding
    ) -> [any CheckoutPort] {
        let erlaubte = rechte.erlaubtePorts(userID: userID)
        return ports.filter { port in
            port.erlaubteInhaltsArten().contains(inhaltsArt)
                && erlaubte.contains(port.id)
        }
    }
}
