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

---

## 5. Bestätigung + Erweiterung (Johannes, 2026-07-02)

**„Bereite dich auf einen bedeutenden Zuwachs in den Katalogen vor."** — die Warenkorb-
Wirbelsäule ist keine Nische, sondern das zentrale Zusammenstell-Prinzip über ALLE Kataloge.

**Jedes Katalog-Element ist ein Pick** — zu Warenkörben zusammenstellbar:
`Kontakt · Notiz · Artikel · Lager · eingehende Angebote · ausgehende Angebote` (bestehende
Kataloge) — und alle künftigen. Nicht nur Artikel/Lager (der heutige Keim), sondern die volle
Matrix. Ein Warenkorb kann also z. B. Kontakt + mehrere Artikel + ein eingehendes Angebot +
eine Notiz gemischt enthalten.

**Perspektivische neue Kataloge** (jeweils eigene Pick-Matrix):
- **Bilderdatenbank-Katalog** (Produkt-/Materialbilder, Herstellerbilder)
- **Dokumenten-Template-Katalog** (Briefpapier/Angebot/Protokoll/Geräteliste …)
- **Textbaustein-Katalog** (wiederverwendbare Textblöcke)
- **Zeichnungs-Katalog** (CAD/Grundrisse/Skizzen)
- … u. v. m.

**Checkout-Ziel-Beispiel (Router):** Produkt-/Materialbilder + Kundenname → **Moodboard-
Generator** mit Auswahl aus den Template-Katalogen. Weitere Ziele analog (Geräteliste-Dokument,
Angebot, Kalkulation, Cross-DB, …).

**Architektur-Konsequenz (für die Vorbereitung):**
- **Pick-Abstraktion generalisieren** über alle Katalog-Matrizen (nicht nur ArtikelItem/LagerItem):
  ein typisierter Verweis `{ matrix, id, snapshot }` je Katalog-Element.
- **Checkout-Target-Registry** (Protokoll `CheckoutTarget`): Moodboard-Generator, Dokument-Render,
  Angebot, Kalkulation … — jedes Ziel nimmt Picks, erzeugt Output über Karte→Bestätigung→Audit.
- Das ist genau die **S10-Grundsatzentscheidung** (Einzelfeatures vs. generische
  DataObject→WorkBasket→CheckoutRun-Pipeline) — sie wird mit Johannes getroffen, BEVOR die
  breite Katalog-Erweiterung + der Moodboard-Generator (S8) gebaut werden.
- Der aktuelle Warenkorb-Feinschliff (Projekt-Zuordnung/Versionierung, Sortieren/Filtern) ist
  ein Baustein davon und sollte die Generalisierung nicht verbauen (keine Artikel-only-Annahmen
  fest verdrahten).

### 5b. Kategorie = Inhalts-Art · Ausgänge = feste Ports (Johannes, 2026-07-02)

**Warenkorb-Kategorie = INHALTS-ART** (was im Korb steckt), nicht der Zweck:
`Artikel · Bilder · Material · Zeichnungen · Textbausteine · Dokumente · gemischt …`

**Checkout = feste, definierte „Ports"** (benannte Verwendungen nach draußen) — eine
**Port-Registry** statt Ad-hoc-Ziele. Die verfügbaren Ports sind teils **inhalts-abhängig**
(eine Inhalts-Art bietet passende Ports an):

| Inhalts-Art (Kategorie) | Passende Ports (Beispiele) |
|---|---|
| Bilder / Material / Zeichnungen | **Firefly-Bild-Prompt-Generator** · Moodboard-Generator |
| Artikel / Positionen | Geräteliste-an-Tischler · Angebot (sevDesk) · Kalkulation |
| Dokumente / Textbausteine | Dokument-Render (Briefpapier-Templates) · Mail-Entwurf |
| gemischt | mehrere Ports gleichzeitig anwählbar |

**Neuer Port — Firefly-Bild-Prompt-Generator:** aus Material- + Moodboard- + Zeichnungs-Picks
(+ Kundenname/Kontext) einen **Adobe-Firefly-Bildgenerierungs-Prompt** erzeugen. Reiner
Prompt-Output (Karte→Bestätigung), keine automatische Bilderzeugung. (Hinweis: eine Adobe-
Firefly/Express-Integration ist perspektivisch als MCP verfügbar — eigener späterer Strang.)

**Konsequenz fürs Datenmodell:** Warenkorb bekommt `inhaltsArt` (Kategorie) + der Checkout
kennt eine `PortRegistry`, die je `inhaltsArt` die zulässigen Ports liefert. Beides gehört in
die S10-Grundsatzentscheidung, bevor breit gebaut wird.

### 5c. Port-Katalog v1 (Arbeitsstand, Johannes bestätigt + erweitert 2026-07-02)

Feste, benannte Ausgänge der Checkout-Registry. Erweiterbar — das ist der lebende Kern.

**Von Johannes bestätigt:**
1. Moodboard (Generator)
2. Geräteliste (an Tischler)
3. Angebot
4. Materialauswahl
5. Bestellung
6. Präsentation
7. Nachtrag zu …

**Ergänzt (Studio-Alltag / vorhandene Fähigkeiten):**
8. Firefly-Bild-Prompt (Material+Moodboard+Zeichnung → Adobe-Firefly-Prompt)
9. Kalkulation / Kostenschätzung (→ KalkulationsEngine)
10. Ausstattungs-/Spec-Liste (Finish Schedule)
11. Auftragsbestätigung
12. Abnahmeprotokoll
13. Aufmaß-/Montageliste
14. Mail-Entwurf / -Versand (Bündel als Mail)
15. Drive-Ablage (Bündel in den Projekt-Ordner)
16. ClickUp-Aufgaben (aus Picks)
17. CAD-/Zeichnungs-Handoff
18. Datenblatt-/Doku-Sammlung

**Reifegrad (fürs Bauen):** 14/15/3/9 nutzen weitgehend Vorhandenes (Mail-Entwurf, Drive-Upload,
Angebots-Erkennung, KalkulationsEngine); 1/8/10 sind neue Renderer/Generatoren; alle laufen über
Karte→Bestätigung→Audit. Liste bleibt offen — neue Ports werden hier ergänzt.

### 5d. Harte Regel — sevDesk-Übergabe nur indirekt, gated, append-only (Johannes, 2026-07-02)

**Grenze bleibt heilig:** mykilOS schreibt NIEMALS direkt an sevDesk (bestehendes NO-GO). Die
Übergabe läuft ausschließlich über eine **Airtable-Übergabe-Tabelle**, aus der sevDesk „abholt"
(Pull außerhalb von mykilOS). mykilOS berührt sevDesk nie.

**Inhalts-Art-Gate:**
- **„Kreativ"-Warenkörbe (Bilder / Moodboard / Zeichnungen / Präsentation / Firefly …) →
  NIE in den sevDesk-Übergabepfad.** Kategorisch ausgeschlossen.
- **Nur geschäftliche Inhalts-Arten** — Artikel / Kunden / Angebote / Cash — dürfen den
  sevDesk-Übergabe-Port überhaupt anbieten.

**Übergabe-Mechanik (Port „sevDesk-Übergabe"):**
- **Doppelte Bestätigung** (zwei getrennte Bestätigungsschritte) vor dem Schreiben.
- Ziel: dedizierte **Übergabe-Airtable-Tabelle** (auf der `writableMap`-Whitelist), eingerichtet
  für sevDesk-Abholung.
- Jeder Übergabe-Record trägt: **feste ID · Erzeuger (Nutzer) · Inhalts-Hash (SHA256 der Picks)**.
- **APPEND-ONLY:** nie überschreiben, nie löschen — immer nur weiterschreiben (deckt sich mit der
  Airtable-Kein-Delete-Regel). Der Inhalts-Hash dient der Dedup/Nachvollziehbarkeit, nicht dem
  Überschreiben.
- Alles zusätzlich lokal als AuditEntry (Karte→Bestätigung→Audit), plus Write-Shadow-Log.

### 5e. Checkout-UX = E-Commerce-Metapher (Johannes, 2026-07-02)

**KEIN Port als eigener Button / großes UI-Element.** Stattdessen genau EIN einheitlicher
**Checkout-Flow** — wie an einer Kasse:

| Shop-Begriff | mykilOS-Bedeutung |
|---|---|
| **„Zahlungsart" wählen** | **Port** wählen (was rauskommt): Angebot · Moodboard · Firefly-Prompt · Kalkulation · Geräteliste · sevDesk-Übergabe … — als Liste, **gefiltert nach Inhalts-Art** des Korbs |
| **„Versandadresse"** | **Ziel/Renderer-Instanz**: z. B. *Firefly Prompter*, *Moodboard Mixer*, *CAD-Zeichnungs-Plandaten*, Drive-Projektordner, sevDesk-Übergabe-Tabelle … (port-spezifische Zielkonfiguration) |
| **„Bestellung bestätigen"** | **Bestätigen** → Ausführung (Karte→Bestätigung→Audit; bei sevDesk **doppelt**) |

**Konsequenzen:**
- Ein Warenkorb → ein Checkout-Sheet: `Port (Zahlungsart) → Ziel (Versandadresse) → Bestätigen`.
- **Neue Ports erscheinen automatisch** in der Port-Liste — kein neues UI je Port. Das UI skaliert
  von selbst mit dem wachsenden Port-Katalog (§5c).
- Verfügbare Ports = `PortRegistry.ports(fuer: inhaltsArt)` — die Inhalts-Art blendet unpassende
  aus (z. B. Kreativ-Korb zeigt keine sevDesk-Übergabe, §5d).
- „Versandadresse" ist port-spezifisch konfigurierbar (Prompt-Parameter, Template-Wahl,
  Ziel-Ordner, Format …) — die einzige Stelle, wo ein Port eigene Felder mitbringt.

### 5f. Port-Rechte (Admin) + Shopify-Katalog vormerken (Johannes, 2026-07-02)

**Port-Berechtigungen — Admin verteilt Rechte:**
- **Nicht alle „Zahlungsarten" (Ports) sind für alle User freigegeben.** Ein **Admin** legt fest,
  welcher Nutzer welche Ports nutzen darf.
- Der PortRegistry-Filter wird damit dreifach: `ports(fuer: inhaltsArt, user:)` =
  **Inhalts-Art-Gate (§5d) ∩ User-Rechte**. Ein User sieht im Checkout nur Ports, die (a) zur
  Inhalts-Art passen UND (b) für ihn freigegeben sind.
- Braucht eine **Admin-Rolle + Rechteverwaltung** (koppelt an Team-/Identitätsmodell + die
  per-User-Härtung von Clockodo/ClickUp). Heikle Ports (z. B. **sevDesk-Übergabe**) sind
  typischerweise nur Finance/Admin.
- Rechte-Quelle: perspektivisch Airtable (pro User → erlaubte Ports), lokal gecacht.

**Shopify-Webshop als Katalog-Quelle (VORMERKEN, später):**
- Ein **Shopify-geführter Webshop** kommt als weitere Katalog-Quelle in die Kataloge
  (Produkte/Varianten/Bestände aus Shopify als Picks). Read-first; Schreibrichtung offen.
- Eigener späterer Strang — jetzt nur als Katalog-Erweiterung vorgemerkt (analog Artikel/Lager,
  aber Quelle = Shopify statt Airtable-Artikel-DB).

### 5g. Picks tragen echten Inhalt — Bilder, Dokumente, Kontaktkarten (Johannes, 2026-07-02)

Ein Pick ist **nicht nur ein Verweis/Metadaten**, sondern muss **übergabefähigen Inhalt** tragen
bzw. auflösen können — damit die Ports echten Content bekommen:
- **Bildmaterial** (Produkt-/Materialbilder, Moodboard-Bilder) — Bytes bzw. auflösbare Drive-/
  Airtable-Attachment-Referenz.
- **Dokumente** (PDF, Datenblätter, Angebote, Zeichnungen) — Datei-Inhalt bzw. Referenz.
- **Kontaktkarten** (Kontaktdaten/vCard) — als Empfänger/Adressat oder Anhang.
- **Textbausteine**, weitere Inhalts-Arten analog.

**Warum:** Moodboard-/Firefly-Ports brauchen die *echten Bilder*; Datenblatt-/Geräteliste-/
Doku-Ports die *echten Dokumente*; Mail-/Übergabe-Ports die *echte Kontaktkarte*.

**Handhabung (Leitplanke):**
- Pick-Snapshot = leichte Referenz + Auflöser; **lazy resolve** zu Bytes erst beim Checkout
  (Warenkörbe bleiben leicht, keine doppelte Binär-Persistenz).
- Große Binärdaten nie unnötig kopieren — Referenz halten, bei Bedarf materialisieren.
- Übergabe folgt weiter Karte→Bestätigung→Audit; Content-Quelle (Drive/Airtable) read-first.

### 5h. Machbarkeit Moodboard · Dokumente · Firefly-I/O (Johannes-Frage, 2026-07-02)

Gemeinsames I/O: **IN** = Picks mit echtem Inhalt (lazy→Bytes, §5g) · **OUT** = Datei (PDF/PNG)
in den Drive-Projektordner + In-App-Vorschau (bzw. Copy beim Firefly-Prompt), über
Karte→Bestätigung→Audit. Für jeden Port: ein **self-contained (nativer) Weg** zuerst, ein
**optionaler Adobe-Pro-Weg** später.

| Port | Nativ (local-first, empfohlen zuerst) | Adobe-Pro (optional, später) |
|---|---|---|
| **Moodboard** | SwiftUI-Board-Layout (Bilder anordnen) → `ImageRenderer` (macOS 13+) → PDF/PNG | HTML → Adobe Express (`export_html_to_express` MCP) |
| **Dokumente** (Briefpapier/Geräteliste/Angebot/Spec) | HTML-Template (vorhandene Briefpapier-Assets) + Pick-Daten → WKWebView/PDFKit → PDF (Muster wie bestehendes build_pdf.sh) | InDesign Data-Merge (`document_merge_data_layout` MCP) |
| **Firefly-Prompt** | Claude (Vision auf Bild-/Material-Picks + Kontext) → **Firefly-Prompt-Text** (Copy) | direkt Bild erzeugen via Adobe-Firefly-MCP (Auth + Kosten) |

**Empfehlung:** nativ zuerst — keine Adobe-Abhängigkeit/Kosten, passt zu local-first; Adobe-Wege
als optionale Ausbaustufe. Template-Wahl = die „Versandadresse" (§5e).

**Vorgemerkt (später):** **Textbausteine-Katalog** als weitere Katalog-Quelle (wiederverwendbare
Textblöcke als Picks, z. B. für Dokument-/Mail-Ports).

### 5i. NEUE REGEL + LEITLINIE — sevDesk-Adapter-„Briefkasten" (Johannes, 2026-07-02)

**Warenkörbe können jetzt an die Airtable-Tabelle `mykilOS_Sevdesk Postbox` übergeben werden.**
Die Tabelle ist ein **Briefkasten**: mykilOS *legt hinein*, sevDesk *holt ab* (Pull außerhalb
von mykilOS) und verarbeitet die Warenkörbe **rechtskonform** zu Angeboten etc.
**mykilOS berührt sevDesk weiterhin NIE direkt — weder schreibend NOCH lesend** (Johannes,
verschärft 2026-07-02). Der Kontakt läuft ausschließlich über **Einweg-Postboxen**: die
`mykilOS_Sevdesk Postbox` ist die Ausgangs-Postbox (mykilOS legt ab → sevDesk holt ab).
Braucht mykilOS umgekehrt sevDesk-Daten (z. B. Ist-Umsatz fürs Cash-Widget), läuft das über
eine **eigene Eingangs-Postbox in Gegenrichtung** (sevDesk schreibt Airtable → mykilOS liest),
nie per direktem sevDesk-Read. ⚠️ **To-Fix:** der heutige direkte `SevdeskClient`-Read (Cash-
Widget) ist damit regelwidrig und muss auf eine Eingangs-Postbox umgestellt werden.
Konkrete Ausformung des §5d-Ports.

**Harte Regeln für die `mykilOS_Sevdesk Postbox`-Tabelle:**
1. **Keine Bilder.** Die Tabelle empfängt niemals Bilddaten (nur Text/Zahlen/Links/Referenzen).
2. **Einmalige Warenkorb-ID.** Jede Übergabe trägt eine **immer identifizierbare, individuelle
   ID** zur Abholung durch sevDesk. IDs sind nie identisch, nie wiederverwendet.
3. **Nie überschreiben, nie löschen.** Append-only. Inaktivierung ausschließlich per Status
   (`inaktiv`) — deckt sich mit der Airtable-Kein-DELETE-Regel. Immer fortschreiben.
4. **Schematisch immer gleich.** Alle Detailangaben, Texte, Links und Angaben aus dem Checkout
   werden in **exakt gleichem Schema** geschrieben (feste Feldstruktur, jede Übergabe gleich geformt).

**Inhalts-Arten, die ein Warenkorb tragen kann:** Kundendaten · Projektdaten · Artikel ·
Textblöcke · Eingangsangebote (oder einzelne Positionen daraus) · Dienstleistungen ·
weitere, noch zu definierende Artikel/Items.

**Pflicht-Übertragungsinhalt je Warenkorb:** Datum · Projekt · Kunde · Zeitstempel · Artikel ·
**Gesamtwert vor Rabatt in EK UND VK** · Fließtexte · alle Details.

**Rückverfolgbarkeit (LEITLINIE, gilt über den Adapter hinaus):** Jedes Feld/Detail muss
einwandfrei in mykilOS zurückverfolgbar sein. **Jedes Katalog-Objekt trägt eine einmalig
vergebene Hash/ID**, die **nicht weitergegeben, kopiert, gelöscht oder verändert** wird.
Warenkorb-Positionen referenzieren diese IDs → lückenlose Rückverfolgung ins Original.
Grundsatz überall: **immer fortschreiben und auf inaktiv setzen, nie löschen oder überschreiben.**

**Erhält/ergänzt aus §5d:** doppelte Bestätigung, Erzeuger (Nutzer) + Inhalts-Hash (SHA256)
je Record, Kreativ-Inhalte (Bilder/Moodboard/Zeichnungen) kategorisch ausgeschlossen, alles
zusätzlich lokal als AuditEntry + Write-Shadow-Log.

**Bau-Ort:** Welle C / C4 — **nach** der S10-Grundsatzentscheidung, nicht vorher. Feld-Schema
(v1) + ID-Schema werden mit Johannes bestätigt, bevor gebaut wird.
