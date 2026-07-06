# 📷 Scanner-Ausbau — Startplan (Johannes 2026-07-06)

**Ziel:** Der Barcode-/QR-/Visitenkarten-Scanner wird zur **Quelle**, die über **steckbare Routen**
(Schaltschrank-Prinzip) zu verschiedenen Zielen führt. Vier konkrete Wünsche:

1. **QR → klickbarer Link.** Enthält ein gescannter QR-Code eine URL, im Output einen **klickbaren
   Link** anbieten (öffnet im Browser).
2. **Visitenkarten-Scanner „heilt" oder legt an.** Karte scannen (OCR) → Dubletten-Check: existiert der
   Kontakt, **anreichern/heilen**; sonst **fragen „anlegen?" → Maske → Kontakt anlegen**.
3. **Barcode → Artikel-Abgleich.** EAN oder ART-NO scannen → in den **Katalogen (Artikel/Geräte)**
   finden + abgleichen.
4. **Aktions-Angebot nach dem Fund.** „Was hast du damit vor?" → **in Katalog ein-/ausbuchen**,
   **in den Warenkorb**, etc.

```
Regel:  Schaltschrank (docs/PRINZIP_SCHALTSCHRANK.md) — Scanner-Quelle, steckbare Ziel-Routen.
        Externe Daten heilig: Kontakte/Artikel nie destruktiv; Daniels Artikel-Base READ ONLY.
        Kontakt-/Lager-Writes gated (Karte→Bestätigung→Audit), nie Auto-Write.
```

## Ist-Stand (Fundament)

| Baustein | Datei | Stand |
|---|---|---|
| **Barcode-/QR-Scanner** (Kamera, Erkennung) | `Sources/MykilosWidgets/Kinds/BarcodeScanner.swift` + `BarcodeWidget.swift` | ✅ liest Codes |
| **Kontakte** (lesen/anlegen) | `GoogleContactsClient`, `ContactsImportView`, `ContactActionCard` (AssistantTool) | ✅ da |
| **Wirbelsäule** (Pick→WorkBasket→Checkout) | `WorkBasketStore`, `CatalogMatrix`, CheckoutPort | ✅ da (Ein-/Ausbuchen/Warenkorb-Ziel) |
| **Geräte-Katalog** | `DeviceCatalog` (Kalkulations-Port) | ✅ da (aber Lookup nach EAN/ART-NO fehlt) |
| **EAN/ART-NO → Artikel-Lookup** | — | 🔴 **fehlt** (der Kern-Neubau) |
| **Visitenkarten-OCR** | — | 🔴 **fehlt** (Vision-Framework, macOS) |

## Bauplan (klein, in Reihenfolge)

**A. QR → Link (klein, sofort):** Scanner-Output-Typ erkennen; ist der Payload eine URL, klickbaren
Link rendern (öffnet Browser). Rein im `BarcodeWidget`. Kein Netzwerk, kein Write.

**B. EAN/ART-NO → Katalog-Lookup (Kern):** Ein `ArtikelLookup`-Service (Schaltschrank-Route):
`gescannter Code → Katalog-Treffer`. Quelle = Scanner; Ziel = Artikel/Geräte-Katalog (DeviceCatalog
+ Airtable-Artikel READ ONLY). Match nach EAN *oder* ART-NO, tolerant. Read-only Anzeige des Treffers.

**C. Aktions-Angebot (Wirbelsäule andocken):** Nach Treffer eine `ScanActionCard` mit steckbaren
Zielen — **Einbuchen / Ausbuchen / In Warenkorb**. Jede Aktion = ein Pick auf die Wirbelsäule
(`Pick{matrix: .artikel/.lager}` → WorkBasket → Checkout). Lager-Writes gated + Audit, nie Daniels
Base überschreiben (Reroute in mykilOS-eigene Base, s. CLAUDE.md).

**D. Visitenkarten → Kontakt:** Vision-OCR der Karte → Felder (Name/Firma/Mail/Tel/Adresse) →
Dubletten-Check gegen Kontakte → **heilen** (bestehenden anreichern) *oder* **Maske + anlegen**
(bestehender `ContactActionCard`-Flow, gated). Airtable-Kontakte als Ziel, nie destruktiv.

## Schaltschrank-Sicht (warum das sauber wird)
Der Scanner emittiert einen **typisierten Scan** (`qr-url | ean | artNo | visitenkarte`). Eine
**Route-Registry** entscheidet das Ziel: URL→Browser, EAN/ART-NO→Katalog-Lookup→Aktionskarte,
Visitenkarte→Kontakt-Heilung. Neue Code-Art oder neues Ziel = neue Route-Zeile, kein Umbau des
Scanners. Deckt sich mit der `FieldRoute`-Registry aus dem ClickUp-Plan.

## Offen für Johannes
- Lager-/Einbuch-Ziel: mykilOS-eigene Base (Daniels Artikel-Base bleibt READ ONLY) — Base-Entscheidung.
- Welche Kataloge sind EAN/ART-NO-durchsuchbar (Geräte? Handelswaren? beide)?
