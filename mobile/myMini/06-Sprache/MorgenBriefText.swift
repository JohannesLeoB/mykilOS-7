import Foundation

/// Reiner Text-Baustein für den gesprochenen Morgen-Brief — getrennt von der
/// View, damit sich der Wortlaut ändern lässt, ohne UI-Code anzufassen.
enum MorgenBriefText {
    static func formuliere(
        begruessung: String,
        projektAnzahl: Int,
        offenePostbox: Int,
        offeneFotos: Int,
        heissesProjekt: String? = nil
    ) -> String {
        var teile = ["\(begruessung).", "\(projektAnzahl) Projekte in der Registry."]

        if let heissesProjekt {
            teile.append("Gerade heiß: \(heissesProjekt).")
        }

        if offenePostbox == 0 {
            teile.append("Die Postbox ist leer.")
        } else {
            let wort = offenePostbox == 1 ? "Eintrag wartet" : "Einträge warten"
            teile.append("\(offenePostbox) \(wort) in der Postbox.")
        }

        if offeneFotos == 0 {
            teile.append("Keine offenen Feld-Fotos.")
        } else {
            let einheit = offeneFotos == 1 ? "Feld-Foto wartet" : "Feld-Fotos warten"
            teile.append("\(offeneFotos) \(einheit) noch auf Sync.")
        }

        return teile.joined(separator: " ")
    }
}
