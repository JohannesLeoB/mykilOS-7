# Formulare-Ebene — gebrandete Firmendokumente aus mykilOS-Daten

**Status: Konzept v1 · 2026-07-02 · Vision von Johannes, Architektur-Vorschlag von Claude.**
Reines Planungsdokument. Größeres mykilOS-8+-Feature.

---

## 1. Vision

Ein eigenes App-Modul **„Formulare"**: eine Bibliothek **gebrandeter Dokument-Vorlagen**,
die sich aus mykilOS-Daten befüllen und als schöne Firmendokumente auf mykilOS-Papier
ausgeben. Die digitale Dateneingabe (Fragebogen, Warenkorb, Projektdaten) wird damit
**wieder als schönes Dokument ausgebbar**.

**Beispiel-Dokumenttypen (offen, wachsend):**
- **Moodboard** (Bildraster + Bildunterschriften, sehr visuell)
- **Brief** (Anschriftfeld, Anrede, Fließtext, Unterschrift)
- **Abnahmeprotokoll** (Formular + Unterschriftsfelder + Mängelliste — = Block F)
- **Geräteliste an Verarbeiter** (z. B. Tischler; tabellenlastig, aus Warenkorb) →
  verknüpft mit der geparkten Erkundung *Gerätelisten-Expand*
- **Präsentation** (mehrseitig, slide-artig, bildreich)
- **Angebot/Kostenaufstellung**, weitere …

---

## 2. Die Kern-Entscheidung: Render-Engine

Der heutige `MykPDFRenderer` (Core Graphics, programmatisch: Titel/Abschnitte/Tabelle/
Summen) ist **gut für strukturierte Formulare**, aber **skaliert NICHT auf „verschiedenste
Vorlagen"** — Moodboards, Präsentationen, Briefe brauchen freie, visuelle Layouts, die man
nicht wirtschaftlich in Core Graphics nachprogrammiert.

### Empfehlung: **HTML/CSS-Vorlage → PDF (via WKWebView)**
| | HTML/CSS → PDF ⭐ | SwiftUI ImageRenderer → PDF | CG-Renderer erweitern |
|---|---|---|---|
| Layout-Vielfalt (Grid/Bild/Slide/Brief) | ✅ universell | 🟡 mittel | ❌ pro Typ Code |
| Design iterierbar (durch Designer/Claude) | ✅ HTML/CSS | ❌ nur Swift | ❌ nur Swift |
| Briefpapier | ✅ CSS-Background + `@page`-Ränder | 🟡 | 🟡 |
| Text vektor/selektierbar, Druckqualität | ✅ | ❌ (rasterisiert) | ✅ |
| Mehrseitigkeit | ✅ CSS `@page` | ❌ manuell | ❌ manuell |
| Daten-Bindung | ✅ Platzhalter füllen | 🟡 | 🟡 |

**Warum HTML/CSS gewinnt:** Es trennt **Design** (Template-Datei, die ein Designer *oder ich*
iteriert) sauber von **Daten** (mykilOS liefert nur ein Daten-Dictionary). Genau das braucht
eine wachsende Vorlagen-Bibliothek. Das **Briefpapier** wird geteiltes CSS (Kopf/Fuß/Ränder).
Native Pipeline: `WKWebView.pdf(configuration:)` (macOS 12+, echte PDF-Paginierung).

> Der bestehende `MykPDFRenderer` bleibt vorerst für die aktuellen einfachen Exporte
> (Fragebogen/Warenkorb) — oder wird als erster Kandidat auf die neue Engine migriert.

---

## 3. Architektur-Skizze

```
Formulare-Ebene
├── DocumentTemplate (Protokoll)        — Name, Typ, benötigte Datenquellen, HTML-Vorlage
├── TemplateRegistry                    — alle verfügbaren Vorlagen (wächst)
├── DocumentDataBinding                 — füllt Platzhalter aus:
│      • Warenkorb (Positionen)         • Projekt/Kunde (mykilOS)
│      • manuelle Eingabe               • Bilder (Drive/lokal)
├── Brand-Layer (geteilt)              — Briefpapier-CSS, Logo, Marken-Schrift (docs/brand)
└── HTMLtoPDFRenderer (WKWebView)       — HTML+Daten → A4-PDF, mehrseitig
```

- **Eine Vorlage = eine HTML-Datei** mit Platzhaltern (`{{kunde.name}}`, `{{#positionen}}…`)
  + Verweis auf das geteilte Brand-CSS.
- **Daten-Dictionary** kommt aus dem jeweiligen Kontext (Warenkorb-Export, Projektseite …).
- **Output:** PDF → Vorschau in-App (bestehender DocumentViewer) → Drive-Upload / Druck.

---

## 3b. Vorlagen verwalten — ändern/ersetzen/löschen/skalieren (pro Kategorie)

**Kernprinzip: Vorlagen sind DATEN, nicht Code.** Genau deshalb sind sie überhaupt
verwaltbar — im Gegensatz zum heutigen Code-Renderer, wo jede Vorlage Swift-Code = ein
Entwickler wäre. Jede Vorlage = HTML/CSS-Datei + Metadaten (`name`, `kategorie`,
`seitenformat`, `thumbnail`, `version`).

- **Kategorien:** jede Vorlage trägt eine `kategorie` (Brief, Moodboard, Abnahmeprotokoll,
  Geräteliste, Präsentation …). Das Formulare-Modul gruppiert danach.
- **Ändern:** Vorlage öffnen → HTML/CSS/Platzhalter anpassen oder Bild-Assets tauschen.
- **Ersetzen:** neue Fassung importieren → als neue **Version** (alte bleibt, kein Verlust).
- **Löschen:** **soft-delete/archivieren** (wie überall in mykilOS nie hart) — jederzeit
  reaktivierbar, „Auf Standard zurücksetzen" möglich.
- **Skalieren, zweifach:** (a) **beliebig viele** Vorlagen (jede ist nur eine Datei);
  (b) **Ausgabeformat pro Vorlage** (A4/A3/Quer, Ränder) als Metadatum — nicht in Code.
- **Speicherort (Vorschlag):** mitgelieferte **Standard-Vorlagen** (read-only Baseline) +
  **Nutzer-/Team-Ebene**. Für ein Team, das dieselben Vorlagen teilt, ist eine **geteilte
  Vorlagen-Bibliothek im Drive** (lokal gecacht) die eleganteste Variante — einer pflegt,
  alle bekommen's.
- **UI:** eigenes „Vorlagen"-Verwaltungs-Panel im Formulare-Modul: Liste je Kategorie,
  je Eintrag Bearbeiten · Duplizieren · Archivieren · Format · Vorschau · „Neu".

## 3c. Wo lagern die Vorlagen + woher die Daten (Empfehlung)

### Speicherort: geteilte Drive-Bibliothek + mitgelieferte Defaults
**Empfehlung:** Vorlagen als HTML/CSS-Dateien in einem **geteilten Drive-Ordner**
`mykilOS/Vorlagen/<Kategorie>/` mit einer **`manifest.json`** (Metadaten je Vorlage:
Name, Kategorie, Seitenformat, Version, aktiv/archiviert). Plus **mitgelieferte
Standard-Vorlagen im App-Bundle** als Offline-/Erststart-Baseline.
- **Warum Drive:** mykilOS ist ohnehin Drive-zentriert (Projekte, Dateien). Team teilt
  automatisch (einer pflegt, alle bekommen's), Versionierung + Backup gratis, local-first
  gecacht (funktioniert offline).
- **Nicht Airtable:** HTML-Dateien sind dort Fremdkörper; Drive ist der richtige Ort für
  Datei-Assets. Airtable bleibt für strukturierte Daten.

### Datenbefüllung: aus dem, was eh schon lokal liegt
**Kernprinzip:** mykilOS ist local-first — die Daten liegen bereits im **lokalen Cache**
(GRDB + Registries). Eine Vorlage wird aus einem **Kontext** erzeugt (ein Projekt, ein
Warenkorb), den die App ohnehin schon geladen hat. **Kein Neu-Laden, keine Doppelung** —
dieselbe Wahrheit wie der Rest der App.

Vorhandene Datenquellen (schon da):
| Quelle (existiert) | liefert |
|---|---|
| `CachedProjectRegistry` / `CachedBusinessRegistry` | Projektnr, Titel, Kunde, (bald) Adresse |
| `CartStore` / `WarenkorbListeStore` | Warenkorb-Positionen, Preise |
| `ArtikelKatalogStore` | Geräte-/Artikeldetails |
| Kontakte-Registry | Adresse, Ansprechpartner |
| `KalkulationsEngine` | Kostenschätzungen |

**Mechanik:** ein `DocumentDataProvider` sammelt aus diesen Stores ein **Daten-Dictionary**
(z. B. `{kunde: …, projekt: …, positionen: […]}`) → füllt die Platzhalter der HTML-Vorlage.
Die Vorlage **deklariert ihren Bedarf** (braucht Kunde+Positionen), der Provider liefert genau
das. Felder, die nirgends existieren (freier Brieftext, Moodboard-Bildauswahl), kommen als
**manuelle Eingabe** in der Erzeugungs-Maske dazu und werden ins Dictionary gemischt.

> Sobald die **Airtable-Core-Konsolidierung** (Adresse am Kunden/Projekt) steht, sind die
> Vorlagen automatisch vollständig befüllbar — beide Stränge greifen ineinander.

## 4. Verbindungen zu bestehenden/geparkten Strängen

- **Brand-Assets** (`docs/brand/README.md`): das Briefpapier/Logo/Schrift-Fundament dieser Ebene.
- **Block F — Abnahmeprotokoll**: wird eine Vorlage *in* dieser Ebene (statt Sonderweg).
- **Geparkte Erkundung „Gerätelisten-Expand"**: die „Geräteliste an Tischler" ist genau eine
  solche Vorlage (Warenkorb → gefiltertes Verarbeiter-Dokument).
- **Warenkorb/Projekt-Daten**: die Datenquellen sind schon da (CartStore, Registry).

---

## 5. Phasen-Vorschlag

1. **Fundament:** `HTMLtoPDFRenderer` (WKWebView) + Brand-CSS aus den gelieferten Assets +
   EINE erste Vorlage (z. B. der Küchenfragebogen als HTML-Nachbau) — Beweis der Engine.
2. **Template-Registry + Daten-Bindung** generalisieren (Warenkorb/Projekt/Kunde).
3. **Formulare-Sidebar-Modul** (UI: Vorlage wählen → Datenquelle → Vorschau → Ausgeben).
4. **Vorlagen-Bibliothek füllen** (Brief, Abnahmeprotokoll, Geräteliste, Moodboard, …) —
   je Vorlage nur noch HTML/CSS, kein neuer Swift-Code.

---

## 6. Offene Fragen (Johannes)

1. **Zeitpunkt:** klar mykilOS 8+ — vor oder nach der Airtable-Core-Konsolidierung?
2. **Erste Vorlage** für den Engine-Beweis: Fragebogen, Abnahmeprotokoll oder Geräteliste?
3. **Moodboard/Präsentation** — Bildquelle: Drive-Ordner des Projekts? Manueller Upload?
4. **Wer pflegt Vorlagen** langfristig — nur ich, oder soll ein einfacher Vorlagen-Editor rein?
