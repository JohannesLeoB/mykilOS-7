# mykilOS — Orchestrierungs-Plan (Resume ab 19:20)

Rolle: **Dirigent.** Von hier scopen + Modell wählen + externe Sub-Sessions delegieren
(spawn_task, Worktree), Branches **verifizieren** (build+test grün, Rails, keine Regression)
vor Integration. Sichtbare Aktivität, keine stillen Loops. DMG an Checkpoints.

## Nordsterne
1. **Warenkorb/Checkout-Wirbelsäule** (`WARENKORB_CHECKOUT.md §1–§5h`) ist die zentrale Architektur.
2. **Zweiter Faden: „wer darf was"** — Identität → per-User-Credentials (Clockodo/ClickUp) → Admin-Port-Rechte.
3. **S1-Live-Abnahme** ist das echte Produktions-Tor (M1/M2, nur mit Johannes).
4. **Bugs vor Features.** Native-first vor Adobe-Pro.

## Modellwahl-Regel
- **Opus/high:** Architektur, Grundsatzentscheidungen, Vision, heikle/rechte-sensible Logik, Renderer-Design.
- **Sonnet/high:** geradlinige Builds auf vorhandenem Fundament.
- **Haiku:** mechanisch/winzig.

## Prioritäten & Wellen

### Welle A — Bugs + Feedback-Politur (parallel, extern)  [SOFORT ab 19:20]
| # | Aufgabe | Modell | int/ext | Quelle |
|---|---|---|---|---|
| A1 | **Warenkorb-Freeze-Bug** (Vorschau/Wiederherstellen = leeres weißes Sheet) — macht Ebene unbenutzbar | Sonnet | ext | Feedback 4/5 |
| A2 | **Angebote-Bug** (alle Belege auf 1 Projekt) + **Filter-Regel** (nie ZIP; PDF/Bild/Mail) | Sonnet | ext | Feedback 3 |
| A3 | **Mail-Kopf-Feinschliff** (Icons größer/Raster · Toggle rechts · Verfassen in Icon-Leiste · CI statt blau) | Sonnet | ext | Feedback 1/2 |
| A4 | **Verify laufende Chips:** Mail-Anhänge (läuft), Bild-Analyse, S11 | — | — | Chips offen |

### Welle B — Entscheidungen (mit Johannes)  [gemeinsam]
| # | Aufgabe | Modell | Hinweis |
|---|---|---|---|
| B1 | **S10 — WorkBasket/Checkout-Grundsatzentscheidung** | Opus | Tor für die ganze Wirbelsäule; danach EINE Pipeline bauen |
| B2 | **S1 — Live-Abnahme A–D + PR nach main** | — | M1/M2, Hustadt-Gate, Block-D-Sandbox → Produktion |

### Welle C — Wirbelsäule bauen (nach S10)
| # | Aufgabe | Modell |
|---|---|---|
| C1 | **Pick-Abstraktion + PortRegistry** (generisch, Inhalts-Art ∩ User-Rechte), Pick trägt echten Inhalt (lazy resolve) | Opus |
| C2 | **Erste native Ports:** Dokument (Briefpapier→PDF, nutzt MykPDFRenderer/Fragebogen) · Moodboard (ImageRenderer) · Firefly-Prompt (Claude-Vision) | Opus/Sonnet |
| C3 | **Warenkorb-Ausbau** (Kategorie=Inhalts-Art · Projekt-Zuordnung/Versionierung · Sortieren/Filtern) — OHNE Artikel-only-Hardwiring | Sonnet |
| C4 | **sevDesk-Übergabe-Port** (Airtable-Pull, Doppel-Bestätigung, ID+Erzeuger+Hash, append-only; Kreativ ausgeschlossen) | Opus |

### Welle D — Identität/Rechte + Breite
| # | Aufgabe | Modell |
|---|---|---|
| D1 | **Per-User Clockodo+ClickUp** (Keychain-Suffix, userID/MemberID beim Connect) + **Admin-Port-Rechte** | Opus |
| D2 | **S9** Kunden-Adressmodell + Maps-Widget + Hero-Bild | Sonnet |
| D3 | **Kataloge selbst-konfigurierbar wie Widgets** (Ein/Aus + Reihenfolge, WidgetSelectorView-Muster) | Sonnet |
| D4 | **Intake-Feinschliff:** Briefpapier-CI im Fragebogen-PDF + **proaktive Dubletten-Warnung** | Sonnet |
| D5 | Totcode `WidgetKind.kalkulation` bereinigen | Haiku |

### P3 — Vormerken (eigene Stränge, später)
Skizzen-Zeichentool im Fragebogen (Canvas→Drive) · Shopify-Katalog · Textbausteine-Katalog ·
Adobe-Pro-Ports (Express/InDesign/Firefly-Bilderzeugung) · Archiv-Drive-Ordner · Screenshot-Feedback laufend.

## Rails (immer)
kein push/merge main · keine externen Notifikationen · ClickUp nur Testspace/Ghost · kein Sevdesk-Write ·
Airtable kein Delete · Secrets nur Keychain · Live/heikles nur mit Johannes · build+test grün + DMG an Checkpoints.

## Startvorschlag 19:20
Welle A parallel delegieren (A1 Freeze zuerst) + die 3 laufenden Chips verifizieren →
dann B1 (S10) mit Johannes entscheiden → Welle C.
