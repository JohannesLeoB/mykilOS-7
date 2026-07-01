# Warenkorb & Checkout — universeller Picker + Router (Wirbelsäule mykilOS 8)

**Status: Konzept v1 · 2026-07-02 · Vision Johannes, Architektur Claude.** Reines Papier.
Deckt sich mit dem Backlog-Eintrag „DataObject→WorkBasket→CheckoutRun→Preview→Review→Audit".

---

## 1. Der Reframe (Johannes 2026-07-02)

Der **Warenkorb ist NICHT „Waren in einem Korb"**, sondern ein **universeller
Sammel-Primitive**: eine dynamische, jederzeit wechselnde Menge von **Picks** aus
*jeder* Datenmatrix von mykilOS:

`Kunde · Produkte · Material · Eingehende Angebote · Artikel · Zeiten · Dienstleistungen · Lager · …`

Der **Checkout ist ein universeller Router**: jeder Pick (oder ein ganzer Korb) lässt
sich über einen smarten, voll ausgebauten Checkout in **beliebige Ziele** schreiben:

`andere DBs · Moodboard-Prompt-Generatoren · Listen · Dokumente · Moodboard-Templates · Angebote · Geräteliste-an-Tischler · …`

---

## 2. Warum das die Wirbelsäule ist

Ein Primitive vereint fast alles, was diese Session konzipiert wurde:
| Ziel-Verwendung | = Picks → | Ziel |
|---|---|---|
| Geräteliste an Tischler | Artikel-Picks → | Dokument ([[FORMULARE_EBENE]]) ins Projekt |
| Moodboard | Bild/Produkt-Picks → | Moodboard-Template |
| Angebot | Artikel/Positions-Picks → | sevDesk (via Airtable) |
| Kalkulation | Modul/Positions-Picks → | KalkulationsEngine |
| Cross-DB-Übergabe | beliebige Picks → | Airtable-Core / Adapter |

→ Verbindet [[FORMULARE_EBENE]], [[AIRTABLE_ARCHITEKTUR]] (Core + Feeder), die geparkte
Gerätelisten-Expand-Erkundung und die Herstellerbilder-DB.

---

## 3. Architektur-Skizze

```
Pick          — ein typisierter Verweis auf ein Objekt (matrix + id + snapshot)
WorkBasket    — geordnete Menge von Picks (dynamisch, versioniert, append-only)
                aktuell: CartStore/Warenkörbe (nur Artikel) → verallgemeinern auf alle Matrizen
CheckoutTarget — Protokoll: nimmt Picks, erzeugt Output (write/render/prompt)
                Ziele: AirtableWrite · DocumentRender (Formulare) · MoodboardPrompt ·
                       GeraetelisteDoc · AngebotSevdesk · …
CheckoutRun   — ein Checkout: Picks + Target → Preview → Bestätigung → Ausführung → Audit
                (Karte→Bestätigung→Audit, wie überall; nie stiller Write)
```

- **Heute vorhanden (Keim):** `CartStore` + Warenkörbe-Tabelle (nur Artikel-Positionen,
  append-only, versioniert) — das ist ein WorkBasket für EINE Matrix. Verallgemeinern.
- **Fehlt:** die Pick-Abstraktion über alle Matrizen + die Target-Registry + die Checkout-
  Preview/Router-UI.

---

## 4. Zugehörige UI-Wünsche aus demselben Batch (2026-07-02)

- **Geräteliste-an-Tischler / Geräte-Checkout:** aus Artikelname, Nr, Bild, Daten, Montage-
  Bild+Link → mykilOS-Briefpapier-Gerätelisten-Dokument ODER -Tabelle, „gedruckt" ins
  ausgewählte Projekt. = ein konkreter CheckoutTarget (DocumentRender) auf Artikel-Picks.
- **Artikel-Anreicherung** (Links/Dokumente/Bilder/Montage/CAD): extern erschlossen, liegt
  aktuell NICHT in der Airtable-Artikel-Tabelle (nur 1 Bild + 1 Link vorhanden). Fundort des
  externen Datensatzes klären (vermutlich lokales DB-Prefill-Paket) → dann als Pick-Snapshot-
  Felder integrieren.

---

## 5. Sequenz
mykilOS 8+. Baut auf 8.0 + der Airtable-Core-Konsolidierung + Formulare-Ebene auf.
Erst diese Fundamente, dann WorkBasket verallgemeinern, dann Target-Registry + Checkout-UI.
