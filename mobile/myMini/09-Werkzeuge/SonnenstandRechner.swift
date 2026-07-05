import Foundation

/// Ein Sonnenstand: Azimut (Himmelsrichtung) + Hoehe ueber dem Horizont.
struct Sonnenstand: Hashable {
    /// Grad, im Uhrzeigersinn von Nord: 0 = N, 90 = O, 180 = S, 270 = W.
    let azimut: Double
    /// Grad ueber dem Horizont; negativ = Sonne unter dem Horizont.
    let hoehe: Double

    var istUeberHorizont: Bool { hoehe > 0 }

    /// Grobe 8-Punkt-Himmelsrichtung fuer die Anzeige ("SW").
    var himmelsrichtung: String {
        let richtungen = ["N", "NO", "O", "SO", "S", "SW", "W", "NW"]
        let index = Int((azimut + 22.5) / 45.0) % 8
        return richtungen[(index + 8) % 8]
    }
}

/// Sonnenstands-Berechnung nach dem NOAA-Solar-Position-Algorithmus.
///
/// **Ehrliche Einordnung:** Das ist die etablierte Standardformel fuer
/// Azimut und Hoehe der Sonne (dieselbe wie im NOAA-Solar-Calculator),
/// genau auf etwa eine Bogenminute — weit mehr als genug fuer die Frage
/// "welches Fenster bekommt Nachmittagssonne". Was sie bewusst NICHT tut:
/// keine atmosphaerische Refraktion dicht am Horizont, und vor allem
/// KEINE Verschattung durch Nachbargebaeude, Baeume oder Dachueberstaende
/// — das waere echte 3D-Geometrie. Die Sonne steht also da, wo hier
/// gerechnet wird; ob sie an dem Punkt WIRKLICH ins Fenster scheint,
/// entscheidet die Umgebung vor Ort.
enum SonnenstandRechner {
    private static func rad(_ grad: Double) -> Double { grad * .pi / 180 }
    private static func grad(_ rad: Double) -> Double { rad * 180 / .pi }

    private static func kalender() -> Calendar {
        var kal = Calendar(identifier: .gregorian)
        kal.timeZone = TimeZone.current
        return kal
    }

    /// Bruchteil-Jahr (rad) — der gemeinsame Winkel aller NOAA-Terme.
    private static func gamma(tagImJahr: Int, stunde: Double) -> Double {
        2 * .pi / 365.0 * (Double(tagImJahr - 1) + (stunde - 12) / 24.0)
    }

    private static func zeitgleichung(_ g: Double) -> Double {
        229.18 * (0.000075 + 0.001868 * cos(g) - 0.032077 * sin(g)
                  - 0.014615 * cos(2 * g) - 0.040849 * sin(2 * g))
    }

    private static func deklination(_ g: Double) -> Double {
        0.006918 - 0.399912 * cos(g) + 0.070257 * sin(g)
            - 0.006758 * cos(2 * g) + 0.000907 * sin(2 * g)
            - 0.002697 * cos(3 * g) + 0.00148 * sin(3 * g)
    }

    /// Sonnenstand fuer einen Zeitpunkt an einem Ort.
    static func berechne(datum: Date, breitengrad lat: Double, laengengrad lon: Double) -> Sonnenstand {
        let kal = kalender()
        let tag = kal.ordinality(of: .day, in: .year, for: datum) ?? 1
        let stunde = Double(kal.component(.hour, from: datum))
        let minute = Double(kal.component(.minute, from: datum))
        let sekunde = Double(kal.component(.second, from: datum))
        let tzStunden = Double(TimeZone.current.secondsFromGMT(for: datum)) / 3600.0

        let g = gamma(tagImJahr: tag, stunde: stunde)
        let eqtime = zeitgleichung(g)
        let decl = deklination(g)

        // Wahre Sonnenzeit -> Stundenwinkel.
        let zeitOffset = eqtime + 4 * lon - 60 * tzStunden          // Minuten
        let wahreSonnenzeit = stunde * 60 + minute + sekunde / 60 + zeitOffset
        let ha = rad(wahreSonnenzeit / 4 - 180)                     // Stundenwinkel (rad)

        let latR = rad(lat)
        let sinHoehe = sin(latR) * sin(decl) + cos(latR) * cos(decl) * cos(ha)
        let hoehe = grad(asin(min(1, max(-1, sinHoehe))))

        // Azimut aus dem Stundenwinkel (von Sued gemessen), dann auf
        // "von Nord im Uhrzeigersinn" gedreht: Mittag -> 180 (Sued).
        let azRoh = atan2(sin(ha), cos(ha) * sin(latR) - tan(decl) * cos(latR))
        var azimut = grad(azRoh) + 180
        if azimut >= 360 { azimut -= 360 }
        if azimut < 0 { azimut += 360 }

        return Sonnenstand(azimut: azimut, hoehe: hoehe)
    }

    /// Sonnenaufgang und -untergang des lokalen Kalendertages. `nil`, wenn
    /// die Sonne an dem Tag gar nicht auf-/untergeht (Polartag/-nacht).
    static func aufUndUntergang(datum: Date, breitengrad lat: Double, laengengrad lon: Double)
        -> (aufgang: Date?, untergang: Date?) {
        let kal = kalender()
        let tag = kal.ordinality(of: .day, in: .year, for: datum) ?? 1
        let g = gamma(tagImJahr: tag, stunde: 12)
        let eqtime = zeitgleichung(g)
        let decl = deklination(g)
        let latR = rad(lat)

        // Zenitwinkel 90,833 Grad = geometrischer Horizont + Refraktion/Radius.
        let cosH0 = cos(rad(90.833)) / (cos(latR) * cos(decl)) - tan(latR) * tan(decl)
        guard cosH0 >= -1, cosH0 <= 1 else { return (nil, nil) }
        let h0 = grad(acos(cosH0))                                  // Halbtagbogen (Grad)

        let aufgangMinUTC = 720 - 4 * (lon + h0) - eqtime
        let untergangMinUTC = 720 - 4 * (lon - h0) - eqtime

        return (datumAusUTCMinuten(aufgangMinUTC, tagesdatum: datum),
                datumAusUTCMinuten(untergangMinUTC, tagesdatum: datum))
    }

    /// Baut aus "Minuten seit UTC-Mitternacht des lokalen Kalendertages"
    /// einen echten Zeitpunkt (der dann lokal formatiert angezeigt wird).
    private static func datumAusUTCMinuten(_ minuten: Double, tagesdatum: Date) -> Date? {
        let lokal = kalender()
        let komponenten = lokal.dateComponents([.year, .month, .day], from: tagesdatum)
        var utcKal = Calendar(identifier: .gregorian)
        guard let utc = TimeZone(identifier: "UTC") else { return nil }
        utcKal.timeZone = utc
        guard let mitternachtUTC = utcKal.date(from: komponenten) else { return nil }
        return mitternachtUTC.addingTimeInterval(minuten * 60)
    }
}
