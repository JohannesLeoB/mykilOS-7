import Foundation
import MykilosKit

// MARK: - ClickUpMetaField (2026-07-06)
// Ein einzelnes ClickUp-Custom-Field, reduziert auf das, was der Meta-Übertrag braucht:
// Feldname (Quell-Ader) + tolerant dekodierter Rohwert. Öffentlich, damit Tests Fake-Felder
// bauen können, ohne die private Decodable-Struktur zu kennen (gleiches Muster wie die
// bestehenden reinen `parse…`-Bausteine des ClickUpClient).
public struct ClickUpMetaField: Sendable, Equatable {
    public let name: String
    public let raw: ClickUpMetaFieldValue

    public init(name: String, raw: ClickUpMetaFieldValue) {
        self.name = name
        self.raw = raw
    }
}

// MARK: - ClickUpMetaFieldValue (2026-07-06)
// Tolerant dekodierter Rohwert eines ClickUp-Custom-Fields. ClickUp liefert `value` je nach
// Feldtyp als Zahl, String, Array oder null — dieser Typ fängt alle Fälle ein, ohne zu brechen.
// Öffentlich (Teil der Parser-Oberfläche, damit Tests/Aufrufer ihn bilden können). Die
// Umsetzung in den Ziel-Swift-Typ macht `ClickUpProjektMetaMapper` je nach Klemme.
public enum ClickUpMetaFieldValue: Decodable, Sendable, Equatable {
    case none
    case zahl(Double)
    case text(String)
    case liste([String])

    // Type-Probing über explizites do/catch (kein verschlucktes Optional-Throw): jede Form wird
    // versucht; ein fehlgeschlagener Versuch (falscher Typ) ist erwartetes Verhalten und wird
    // bewusst verworfen, der nächste Typ kommt dran. Reihenfolge: null → Zahl → String →
    // String-Array → Label-Objekte → sonst none.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .none
            return
        }
        do { self = .zahl(try container.decode(Double.self)); return } catch { /* nächster Typ */ }
        do { self = .text(try container.decode(String.self)); return } catch { /* nächster Typ */ }
        do { self = .liste(try container.decode([String].self)); return } catch { /* nächster Typ */ }
        do {
            // Labels (multi) kommen als Array von Objekten mit `name`/`label` — auf Klartext heben.
            let labels = try container.decode([LabelEntity].self)
            let namen = labels.compactMap { $0.label ?? $0.name }
            self = namen.isEmpty ? .none : .liste(namen)
            return
        } catch { /* unbekannte Form */ }
        // Unbekannte Form (z. B. verschachteltes Objekt) tolerant ignorieren.
        self = .none
    }

    private struct LabelEntity: Decodable {
        var name: String?
        var label: String?
    }
}

// MARK: - ClickUpProjektMetaMapper (2026-07-06)
// Der Schaltschrank auf der Parse-Seite (docs/PRINZIP_SCHALTSCHRANK.md): läuft die eingehenden
// Felder durch die Route-Tabelle und legt jede gefundene Ader auf ihre Ziel-Klemme — statt 13
// harter if-Zweige. Umlegen = Route-Zeile ändern, nicht diesen Mapper. Tolerant: unbekannte
// Felder, stillgelegte Routen und typ-fremde Rohwerte werden übersprungen, nie brechend.
public enum ClickUpProjektMetaMapper {
    /// Hebt die `custom_fields` einer ClickUp-Tasks-Antwort in ein typisiertes `ClickUpProjektMeta`
    /// — über die umsteckbare `ClickUpFieldRouteRegistry` (nicht 13 harte if-Zweige). Die 13
    /// Projekt-Custom-Fields sind Space-Ebene und erscheinen auf jeder Task der Liste; ausgewertet
    /// wird die ERSTE Task, die überhaupt Custom-Fields trägt. Reiner Lese-Übertrag — kein
    /// Schreiben, kein Netzwerk. Fehlt ein Feld/eine Task, bleibt der Slot nil (nie brechend).
    /// Wirft `ClickUpError.decodingFailed` nur bei komplett kaputtem JSON.
    public static func parse(
        from data: Data,
        routes: ClickUpFieldRouteRegistry = .default
    ) throws -> ClickUpProjektMeta {
        let decoded: MetaTasksResponse
        do {
            decoded = try JSONDecoder().decode(MetaTasksResponse.self, from: data)
        } catch {
            throw ClickUpError.decodingFailed
        }
        guard let fields = decoded.tasks.first(where: { ($0.customFields?.isEmpty == false) })?.customFields else {
            return .empty
        }
        let paare = fields.map { ClickUpMetaField(name: $0.name, raw: $0.value) }
        return map(fields: paare, routes: routes)
    }

    public static func map(
        fields: [ClickUpMetaField],
        routes: ClickUpFieldRouteRegistry = .default
    ) -> ClickUpProjektMeta {
        var meta = ClickUpProjektMeta.empty
        for field in fields {
            guard let route = routes.route(fuerQuelle: field.name) else { continue }
            lege(field.raw, aufKlemme: route.ziel, in: &meta)
        }
        return meta
    }

    /// Legt einen Rohwert typgerecht auf die Ziel-Klemme. Der Ziel-`kind` wählt die Umsetzung
    /// (Currency→Double, Date→Date, Text→String, Labels→[String]) und den Key-Path-Slot; passt
    /// der Rohwert nicht zum erwarteten Typ, bleibt der Slot unberührt (tolerant). Bewusst über
    /// die Key-Paths am Slot statt 13 if-Zweige — hält die Verzweigung flach.
    private static func lege(
        _ raw: ClickUpMetaFieldValue,
        aufKlemme slot: ClickUpMetaSlot,
        in meta: inout ClickUpProjektMeta
    ) {
        switch slot.kind {
        case .zahl:
            if let keyPath = slot.doubleKeyPath, let value = zahl(raw) { meta[keyPath: keyPath] = value }
        case .datum:
            if let keyPath = slot.dateKeyPath, let value = datum(raw) { meta[keyPath: keyPath] = value }
        case .text:
            if let keyPath = slot.textKeyPath, let value = text(raw) { meta[keyPath: keyPath] = value }
        case .textListe:
            if let keyPath = slot.listKeyPath, let value = liste(raw) { meta[keyPath: keyPath] = value }
        }
    }

    // MARK: Roh → Zieltyp (tolerant)

    private static func zahl(_ raw: ClickUpMetaFieldValue) -> Double? {
        switch raw {
        case .zahl(let value): return value
        case .text(let value): return Double(value)   // Currency kann als String kommen.
        default:               return nil
        }
    }

    /// ClickUp-Datumsfelder liefern Epoch-MILLISEKUNDEN — als String (üblich) oder Zahl.
    private static func datum(_ raw: ClickUpMetaFieldValue) -> Date? {
        switch raw {
        case .text(let value):
            guard let millis = Double(value) else { return nil }
            return Date(timeIntervalSince1970: millis / 1000.0)
        case .zahl(let millis):
            return Date(timeIntervalSince1970: millis / 1000.0)
        default:
            return nil
        }
    }

    private static func text(_ raw: ClickUpMetaFieldValue) -> String? {
        switch raw {
        case .text(let value):
            let getrimmt = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return getrimmt.isEmpty ? nil : getrimmt
        default:
            return nil
        }
    }

    private static func liste(_ raw: ClickUpMetaFieldValue) -> [String]? {
        switch raw {
        case .liste(let values):
            let sauber = values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
            return sauber.isEmpty ? nil : sauber
        case .text(let value):
            // Ein einzelnes Label kann als String kommen → als 1-Element-Liste heben.
            let getrimmt = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return getrimmt.isEmpty ? nil : [getrimmt]
        default:
            return nil
        }
    }
}

// MARK: - Decodable-Pfad für den Meta-Übertrag
// Minimal: nur `tasks[].custom_fields[].{name,value}` — bewusst getrennt vom Task-Decodable des
// ClickUpClient (das den Int-Orderindex für `project_phase` liest). Hier ist `value` der tolerant
// dekodierte Rohwert (`ClickUpMetaFieldValue`). Die Entitäten liegen top-level (nicht verschachtelt),
// damit ihre CodingKeys nur eine Ebene tief sind.
private struct MetaTasksResponse: Decodable {
    var tasks: [MetaTaskEntity]
}

private struct MetaTaskEntity: Decodable {
    var customFields: [MetaFieldEntity]?

    enum CodingKeys: String, CodingKey {
        case customFields = "custom_fields"
    }
}

private struct MetaFieldEntity: Decodable {
    var name: String
    var value: ClickUpMetaFieldValue

    private enum CodingKeys: String, CodingKey { case name, value }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        // Fehlender Schlüssel → .none. `ClickUpMetaFieldValue` selbst wirft nie (löst immer auf
        // eine Case auf, notfalls .none) — daher genügt `decodeIfPresent`.
        value = try container.decodeIfPresent(ClickUpMetaFieldValue.self, forKey: .value) ?? .none
    }
}
