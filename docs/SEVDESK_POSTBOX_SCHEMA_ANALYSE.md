# sevDesk-Postbox — Feldanalyse aus den Standard-Templates & Schema-Vorschlag

**Stand:** 2026-07-04 · Quelle: 9 sevDesk-Standard-HTML-Templates (`~/Desktop/mykilos Letter/sevdesk Standard Templates/`)
**Zweck:** Das Datenmodell ableiten, das sevDesk real braucht, um daraus das Briefkasten-Airtable
(Einweg-Postbox) so aufzubauen, dass ein Mensch in sevDesk einen Beleg daraus rekonstruieren kann.

> ⛔ mykilOS stellt NIE selbst Angebote/Rechnungen/belegführende Dokumente aus. Der Briefkasten
> transportiert nur Positions-/Kontextdaten. **Belegnummern vergibt ausschließlich sevDesk** (es gibt
> noch keinen definierten NUMMERNBOSS) — unser Postbox-Schema hält daher KEIN eigenes Belegnummern-Feld
> als Autorität; es kann höchstens eine *fremde Referenznummer als Klartext* mitführen.
>
> **sevDesk = BOSSMODE (Johannes, 2026-07-04):** Absolute Mengen, Margen und Steuer sind IMMER sevDesks
> Hoheit. Alle kaufmännischen Postbox-Felder (`Netto-/Brutto-Summe`, `Einzelpreis`, `Gesamtpreis`,
> `MwSt-%`, `Rabatt`) sind **Vorschlag/Gegenprobe, nie verbindlich**. mykilOS kann immer nur
> **vorschlagen — nie durchreichen, nie vorschreiben.** Der Drop ist ein Vorschlag; ein Mensch in
> sevDesk entscheidet und baut den echten Beleg. Künftige In-App-Dokumenten-Modi (schön/kreativ)
> bleiben beschriftete Vorschau-/Arbeitsdokumente, nie offizielle Belege.

---

## 1 · Was die Templates verraten (sevDesks echtes Datenobjekt)

Alle belegartigen Templates (Order, Auftragsbestätigung, Lieferschein, Gutschrift, Rechnung, Mahnung)
teilen sich **exakt dieselbe zweistufige Struktur**: ein Beleg-Kopf (`data.object.*`) + eine Positionsliste
(`data.object.positions[]`). Das ist die Blaupause.

### 1a · Beleg-Ebene (`data.object`) — pro Dokument einmalig

| sevDesk-Feld | Bedeutung | Für Postbox relevant? |
|---|---|---|
| `header` | Betreff/Überschrift des Belegs | ✅ |
| `head_text` | Einleitungstext (HTML) | ✅ |
| `foot_text` | Schlusstext (HTML) | ✅ |
| `address` | Empfänger-Adressblock (mehrzeilig) | ✅ (→ aus Projekt/Kunde) |
| `contact_person` | Ansprechpartner | ⚪ optional |
| `customer_number` | Kundennummer | ✅ (Referenz, nicht Autorität) |
| `customer_internal_note` | interne Notiz | ⚪ optional |
| `*_number` (`order_number`, `invoice_number`, `credit_note_number` …) | **sevDesk-Belegnummer** | ❌ **nie von uns** — sevDesk vergibt |
| `*_date` (`order_date`, `invoice_date` …) | Belegdatum | ⚪ sevDesk setzt beim Anlegen |
| `delivery_date` / `delivery_date_until` | Leistungsdatum/-zeitraum | ⚪ optional |
| `delivery_terms` / `payment_terms` / `payment_method_text` | Liefer-/Zahlungsbedingungen | ⚪ optional |
| `show_net` | Netto- vs. Bruttodarstellung | ✅ (Steuerkontext) |
| `tax_type_rule` | Steuerregel (z.B. Reverse-Charge, §13b) | ✅ (Steuerkontext) |
| `has_discounts` / `discounts[]` | Beleg-Rabatte (Skonto etc.) | ⚪ optional |
| `total_net` / `total` (brutto) / VAT | Summen | ✅ (als Gegenprobe, nicht Quelle) |

### 1b · Positions-Ebene (`data.object.positions[]`) — der Kern

Jede Position ist **entweder** eine echte Zeile (`pos_nr` gesetzt) **oder** eine Gruppen-Überschrift
(`pos_nr` leer → nur `name`/`text` als Zwischentitel). Das erklärt, wie sevDesk verschachtelte
Angebote gruppiert.

| sevDesk-Feld | Bedeutung | Haben wir schon? |
|---|---|---|
| `pos_nr` | Positionsnummer (bzw. leer = Gruppentitel) | teilweise (Seite/Index) |
| `name` | Positions-**Titel** | ✅ (Positionstext) |
| `text` | Positions-**Beschreibung** (Langtext, HTML) | ✅ (voller Original-Text) |
| `part_number` | **Artikelnummer** | ✅ **`OfferPositionExtractor.artikelnummer`** |
| `quantity` | Menge | 🟡 (extrahierbar, noch nicht sauber gefeldet) |
| `unity_name` | Einheit (Stk, m, m², h …) | 🟡 |
| `tax_price` | **Einzelpreis** (netto/brutto je `show_net`) | 🟡 |
| `total` | **Gesamtpreis** der Position | 🟡 |
| `tax_rate` | MwSt-Satz % pro Position | 🟡 |
| `discount` / `is_percentage` / `discounted_value` | Positionsrabatt | ⚪ |
| `optional` | Optionalposition (Bool → „Opt.“) | ⚪ |
| `hide_quantity` | Menge ausblenden | ⚪ |

**Befund:** Unser `PickSnapshot` deckt heute `name`+`text`+`part_number`+Quelle/Seite/Richtung ab. Was für
einen sevDesk-tauglichen Drop fehlt, sind die **kaufmännischen Felder pro Position**: `quantity`,
`unity_name`, `tax_price` (Einzelpreis), `total`, `tax_rate`. Die stehen im Original-Positionstext meist
drin — der Extractor müsste sie in eigene Felder ziehen (Ausbaustufe, kein Blocker fürs Schema).

---

## 2 · Vorgeschlagenes Postbox-Schema (Airtable, Base `appuVMh3KDfKw4OoQ`)

Spiegelt sevDesks eigene Beleg→Positionen-Verschachtelung 1:1. Zwei verlinkte Tabellen.
Append-only, per-Objekt-Hash, keine echte Belegnummer, volle Rückverfolgbarkeit (deckt sich mit der
bestehenden sevDesk-Adapter-Briefkasten-Leitlinie).

### Tabelle A — `Postbox-Beleg` (Kopf/Kontext, 1 Zeile pro gedroptem Beleg)
- `Postbox-ID` (Text, eindeutig, unser Handle — NICHT die sevDesk-Nummer)
- `Objekt-Hash` (SHA256 über den Beleginhalt → Idempotenz/Dedup)
- `Status` (Single-Select: `Neu` / `In sevDesk übernommen` / `Verworfen` — nie DELETE)
- `Beleg-Typ` (Single-Select: Angebot / Rechnung / Gutschrift / Lieferschein / Auftragsbestätigung)
- `Projekt` (Link → Projekte)
- `Kunde` / `Kundennummer` (Referenz, Klartext)
- `Lieferant` (bei eingehenden Angeboten: von wem)
- `Fremd-Referenznummer` (Klartext, z.B. Nummer vom Tischler-Angebot — NIE als Autorität behandelt)
- `Betreff` (`header`), `Einleitungstext` (`head_text`), `Schlusstext` (`foot_text`)
- `Netto-Summe` / `Brutto-Summe` (Gegenprobe)
- `Steuer-Kontext` (`show_net`, `tax_type_rule` als Text)
- `Quelldatei` (Drive-Link/Name), `Quell-Seite`
- `Importiert-am`, `Importiert-von` (User)

### Tabelle B — `Postbox-Position` (N Zeilen, Link → Postbox-Beleg)
- `Beleg` (Link → Postbox-Beleg)
- `Positions-Hash` (SHA256 pro Position)
- `Pos-Nr` (bzw. leer = Gruppentitel; `Ist-Gruppentitel` Bool)
- `Titel` (`name`), `Beschreibung` (`text`)
- `Artikelnummer` (`part_number`) ← haben wir
- `Menge` (`quantity`), `Einheit` (`unity_name`)
- `Einzelpreis` (`tax_price`), `Gesamtpreis` (`total`), `MwSt-%` (`tax_rate`)
- `Rabatt` / `Rabatt-%` (optional)
- `Optional-Position` (Bool)
- `Richtung` (eingehend/ausgehend — bestehendes Attribut)

---

## 2b · Angelegt (2026-07-04, Base `appuVMh3KDfKw4OoQ`)

Johannes hat „zwei Tabellen" gewählt. Live angelegt (Test-Konvention der Base: `Status=Test` statt
separater `-TEST`-Tabellen — analog `TEST-Projekte`):

- **`Postbox-Beleg`** = `tbluQiYMVllkTS4jQ` (Primär `Postbox-ID`; Status-Choices: Test/Neu/In sevDesk übernommen/Verworfen)
- **`Postbox-Position`** = `tblfVRnwgaxvXPfOK` (Primär `Positions-ID`; Link `Beleg` → Postbox-Beleg)

⚠️ **Noch offen (Datenstrom-Handbuch):** Ein `SEVDESK_POSTBOX_DROP`-Eintrag ins Handbuch
(`tblaUVftka0GvXzeU`) + `DatastromManifest.json` kommt erst mit dem Code-Write-Pfad (die
`integrationID` muss exakt zum `DataFlowLogger.log()`-Aufruf passen) — beim Bau des CheckoutPort.

---

## 3 · Erledigte Design-Entscheidung

**Zwei Tabellen (Beleg + Positionen, verlinkt)** — wie oben, spiegelt sevDesk exakt — **ODER**
**eine flache Tabelle (1 Zeile pro Position, Belegkontext als wiederholte Spalten)**?

- **Zwei Tabellen (Empfehlung):** sauber, matcht sevDesks Modell, ein Hash pro Beleg UND pro Position,
  Gruppentitel sauber abbildbar. Kostet: eine Verknüpfung mehr in der App.
- **Flach:** einfacher zu schreiben/lesen, aber Belegkontext redundant pro Zeile, Gruppentitel unschön.

Empfehlung: **Zwei Tabellen.** Wenn du zustimmst, lege ich sie an (Testtabellen zuerst) und verdrahte
den `CheckoutPort`.
