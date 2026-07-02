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
