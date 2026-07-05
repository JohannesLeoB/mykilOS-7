import SwiftUI

// MARK: - MykMotion (Bewegungs-Tokens, Schönheits-Kampagne Akt 2)
//
// EINE Bewegungssprache für die ganze App — wie MykColor für Farbe und MykSpace
// für Raum. Alle Animationen greifen auf diese Tokens zu, damit sich überall
// dieselbe „Physik" anfühlt. Keine Ad-hoc-Dauern mehr in Views.
public enum MykMotion {
    /// Mikro-Feedback: Hover, Toggles, kleine Zustandswechsel.
    public static let hover = Animation.easeInOut(duration: 0.15)
    /// Standard-Übergang: Ein-/Ausblenden von Sektionen, Aufklappen.
    public static let ease = Animation.easeInOut(duration: 0.22)
    /// Räumlich: Karten/Kacheln, die sich bewegen oder umfließen — federnd, ruhig.
    public static let spring = Animation.spring(response: 0.34, dampingFraction: 0.82)
    /// Blättern im Viewer (Galerie-Flug): schnell, gerichtet.
    public static let page = Animation.easeOut(duration: 0.18)

    /// Hover-Anhebung von Kacheln/Karten (Skalierung).
    public static let hoverScale: CGFloat = 1.03
    /// Schatten-Paar für Ruhe/Hover (Radius, Y-Versatz, Opazität).
    public static let restShadow:  (radius: CGFloat, y: CGFloat, opacity: Double) = (6, 2, 0.05)
    public static let hoverShadow: (radius: CGFloat, y: CGFloat, opacity: Double) = (18, 8, 0.12)
}
