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
