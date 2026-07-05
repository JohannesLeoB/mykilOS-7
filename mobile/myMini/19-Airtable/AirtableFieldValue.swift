import Foundation

/// Minimale, mobile-eigene Abbildung von Airtable-Feldwerten. Bewusst kein
/// geteilter Code mit dem Mothership-Äquivalent (Zwei-Tank-Doktrin) — nur
/// dieselbe Form nachgebaut.
enum AirtableFieldValue {
    case string(String)
    case number(Double)

    var jsonValue: Any {
        switch self {
        case .string(let value): return value
        case .number(let value): return value
        }
    }
}
