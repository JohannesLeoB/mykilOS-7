import AppKit
import PDFKit
import MykilosDesign

// MARK: - MykPDFRenderer
// Wiederverwendbarer PDF-Builder im mykilOS-Stil (A4-Hochformat, Terrakotta-Akzent).
// Reine Funktion — kein Netzwerk, kein Airtable, kein Keychain.
// Wird von Fragebogen-Export UND Warenkorb-Export genutzt.
//
// API:
//   MykPDFRenderer.render(title:sections:table:totals:) -> Data
//
// sections: [(heading: String, fields: [(label: String, value: String)])]
// table:    [[String]]  — erste Zeile = Kopfzeile (optional)
// totals:   [(label: String, value: String)] — Summenblock unter der Tabelle

public enum MykPDFRenderer {

    // MARK: - Layout-Konstanten (A4 @ 72 dpi)

    private static let pageWidth:  CGFloat = 595.28
    private static let pageHeight: CGFloat = 841.89
    private static let marginH:    CGFloat = 48
    private static let marginTop:  CGFloat = 56
    private static let marginBot:  CGFloat = 40
    private static var contentWidth: CGFloat { pageWidth - 2 * marginH }

    // Farben aus MykColor-Token (AppKit-Welt, kein SwiftUI nötig).
    private static var colorInk:    NSColor { NSColor(hex: "#1A1814") ?? .black }
    private static var colorBrand:  NSColor { NSColor(hex: "#EA5B25") ?? .orange }
    private static var colorDrive:  NSColor { NSColor(hex: "#C26B4A") ?? .brown }
    private static var colorPaper:  NSColor { NSColor(hex: "#FAF8F3") ?? .white }
    private static var colorBorder: NSColor { NSColor(hex: "#E0DDD7") ?? .lightGray }

    // MARK: - Öffentliche API

    /// Rendert ein A4-PDF im mykilOS-Stil.
    ///
    /// - Parameters:
    ///   - title:    Dokumenttitel (groß, Kopfzeile).
    ///   - subtitle: Optionaler Untertitel/Projektname unter dem Titel.
    ///   - sections: Abschnitte mit je einem Heading + Feldliste (label/value-Paare).
    ///   - table:    Optionale Tabelle — erste Zeile = Kopfzeile, weitere = Datenzeilen.
    ///   - totals:   Summenpositionen unter der Tabelle (label/value, rechtsbündig).
    ///   - footerNote: Optionaler Hinweis in der Fußzeile (z. B. „Kalkulations-Vorschau —
    ///                 kein offizielles Angebot"). Additiv, `nil` = bisheriges Verhalten.
    /// - Returns: PDF-Daten (Data), fertig zum Schreiben oder Hochladen.
    public static func render(
        title: String,
        subtitle: String? = nil,
        sections: [(heading: String, fields: [(label: String, value: String)])],
        table: [[String]]? = nil,
        totals: [(label: String, value: String)] = [],
        footerNote: String? = nil
    ) -> Data {
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        // Single-page render — bei langen Dokumenten ggf. auf mehrere Seiten ausdehnen.
        ctx.beginPDFPage(nil)

        // Weißer Hintergrund
        ctx.setFillColor(colorPaper.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        var cursor: CGFloat = pageHeight - marginTop

        // Kopfzeile: Terrakotta-Akzentlinie + Titel
        drawHeaderLine(ctx: ctx, y: cursor)
        cursor -= 6

        cursor -= drawText(
            ctx: ctx,
            text: title.uppercased(),
            x: marginH,
            y: cursor,
            width: contentWidth,
            font: .boldSystemFont(ofSize: 18),
            color: colorBrand
        )
        cursor -= 4

        if let sub = subtitle {
            cursor -= drawText(
                ctx: ctx,
                text: sub,
                x: marginH,
                y: cursor,
                width: contentWidth,
                font: .systemFont(ofSize: 11),
                color: colorInk.withAlphaComponent(0.6)
            )
        }

        cursor -= 14

        // Datums-Zeile rechts
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        drawText(
            ctx: ctx,
            text: dateStr,
            x: marginH,
            y: cursor + 2,
            width: contentWidth,
            font: .systemFont(ofSize: 9),
            color: colorInk.withAlphaComponent(0.45),
            alignment: .right
        )
        cursor -= 16

        // Trennlinie
        drawHRule(ctx: ctx, y: cursor, color: colorBorder)
        cursor -= 14

        // Abschnitte
        for section in sections {
            cursor -= drawSectionHeading(ctx: ctx, text: section.heading, y: cursor)
            cursor -= 6
            for field in section.fields {
                cursor -= drawFieldRow(ctx: ctx, label: field.label, value: field.value, y: cursor)
                cursor -= 2
            }
            cursor -= 12
        }

        // Tabelle
        if let rows = table, !rows.isEmpty {
            drawHRule(ctx: ctx, y: cursor, color: colorBorder)
            cursor -= 12
            cursor -= drawTable(ctx: ctx, rows: rows, y: cursor)
            cursor -= 8
        }

        // Summenblock
        if !totals.isEmpty {
            drawHRule(ctx: ctx, y: cursor, color: colorBorder)
            cursor -= 10
            for total in totals {
                cursor -= drawTotalRow(ctx: ctx, label: total.label, value: total.value, y: cursor)
                cursor -= 2
            }
        }

        // Fußzeile
        drawFooter(ctx: ctx, note: footerNote)

        ctx.endPDFPage()
        ctx.closePDF()

        return pdfData as Data
    }

    // MARK: - Zeichenhilfen (privat)

    @discardableResult
    private static func drawText(
        ctx: CGContext,
        text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        font: NSFont,
        color: NSColor,
        alignment: NSTextAlignment = .left
    ) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let framesetter = CTFramesetterCreateWithAttributedString(str)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: 0),
            nil,
            CGSize(width: width, height: 2000),
            nil
        )
        let textRect = CGRect(x: x, y: y - size.height, width: width, height: size.height)
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        CTFrameDraw(frame, ctx)
        return size.height
    }

    private static func drawHeaderLine(ctx: CGContext, y: CGFloat) {
        ctx.setFillColor(colorBrand.cgColor)
        ctx.fill(CGRect(x: marginH, y: y - 2, width: contentWidth, height: 3))
    }

    private static func drawHRule(ctx: CGContext, y: CGFloat, color: NSColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: marginH, y: y - 0.5, width: contentWidth, height: 0.75))
    }

    @discardableResult
    private static func drawSectionHeading(ctx: CGContext, text: String, y: CGFloat) -> CGFloat {
        drawText(
            ctx: ctx,
            text: text.uppercased(),
            x: marginH,
            y: y,
            width: contentWidth,
            font: .boldSystemFont(ofSize: 9),
            color: colorDrive
        )
    }

    @discardableResult
    private static func drawFieldRow(
        ctx: CGContext, label: String, value: String, y: CGFloat
    ) -> CGFloat {
        let labelWidth: CGFloat = 160
        let valueX = marginH + labelWidth + 8
        let valueWidth = contentWidth - labelWidth - 8

        let h1 = drawText(ctx: ctx, text: label, x: marginH, y: y, width: labelWidth,
                          font: .systemFont(ofSize: 9), color: colorInk.withAlphaComponent(0.55))
        let h2 = drawText(ctx: ctx, text: value, x: valueX, y: y, width: valueWidth,
                          font: .systemFont(ofSize: 9), color: colorInk)
        return max(h1, h2)
    }

    private static func drawTable(ctx: CGContext, rows: [[String]], y: CGFloat) -> CGFloat {
        guard let header = rows.first else { return 0 }
        let columnCount = header.count
        guard columnCount > 0 else { return 0 }

        let colWidth = contentWidth / CGFloat(columnCount)
        let rowHeight: CGFloat = 16
        var totalHeight: CGFloat = 0
        var cursor = y

        for (i, row) in rows.enumerated() {
            let isHeader = i == 0
            // Zeilenhintergrund für Kopfzeile
            if isHeader {
                ctx.setFillColor(colorDrive.withAlphaComponent(0.08).cgColor)
                ctx.fill(CGRect(x: marginH, y: cursor - rowHeight, width: contentWidth, height: rowHeight))
            }
            for (j, cell) in row.prefix(columnCount).enumerated() {
                let cellX = marginH + CGFloat(j) * colWidth + 4
                drawText(
                    ctx: ctx,
                    text: cell,
                    x: cellX,
                    y: cursor - 3,
                    width: colWidth - 8,
                    font: isHeader ? .boldSystemFont(ofSize: 8) : .systemFont(ofSize: 8),
                    color: colorInk
                )
            }
            cursor -= rowHeight
            totalHeight += rowHeight
            // Zellentrennlinie
            drawHRule(ctx: ctx, y: cursor, color: colorBorder.withAlphaComponent(0.5))
        }
        return totalHeight
    }

    @discardableResult
    private static func drawTotalRow(ctx: CGContext, label: String, value: String, y: CGFloat) -> CGFloat {
        let labelWidth: CGFloat = contentWidth - 120
        let valueX = marginH + labelWidth
        let h1 = drawText(ctx: ctx, text: label, x: marginH, y: y, width: labelWidth,
                          font: .systemFont(ofSize: 9), color: colorInk.withAlphaComponent(0.7))
        let h2 = drawText(ctx: ctx, text: value, x: valueX, y: y, width: 110,
                          font: .boldSystemFont(ofSize: 9), color: colorInk, alignment: .right)
        return max(h1, h2)
    }

    private static func drawFooter(ctx: CGContext, note: String? = nil) {
        let footerY: CGFloat = marginBot - 4
        drawHRule(ctx: ctx, y: footerY + 12, color: colorBorder)
        // Optionaler Hinweis (z. B. Vorschau-Beschriftung) knapp über der Fußzeile —
        // sichtbar in Terrakotta, damit ein Vorschau-PDF nie wie ein Beleg wirkt.
        if let note, note.isEmpty == false {
            drawText(
                ctx: ctx,
                text: note,
                x: marginH,
                y: footerY + 22,
                width: contentWidth,
                font: .systemFont(ofSize: 7.5),
                color: colorDrive
            )
        }
        drawText(
            ctx: ctx,
            text: "MYKILOS · mykilos.com",
            x: marginH,
            y: footerY,
            width: contentWidth / 2,
            font: .systemFont(ofSize: 7),
            color: colorInk.withAlphaComponent(0.35)
        )
        drawText(
            ctx: ctx,
            text: "Seite 1",
            x: marginH + contentWidth / 2,
            y: footerY,
            width: contentWidth / 2,
            font: .systemFont(ofSize: 7),
            color: colorInk.withAlphaComponent(0.35),
            alignment: .right
        )
    }
}

// MARK: - NSColor(hex:) Convenience
// Lokal in diesem File um Abhängigkeit auf MykilosDesign Color(hex:) zu vermeiden
// (MykilosApp importiert MykilosDesign, aber NSColor wird direkt benötigt).
private extension NSColor {
    convenience init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let value = UInt64(h, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >>  8) & 0xFF) / 255
        let b = CGFloat((value      ) & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
