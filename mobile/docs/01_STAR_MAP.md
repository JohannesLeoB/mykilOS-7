# Sternenkarte — Beobachtungsjournal des Mothership

**Jede Peilung ist an eine Sternposition (Commit-SHA) genagelt → reproduzierbar.**
Der Stern wandert (im Stundentakt). Peilungen altern. Vor jeder neuen Deutung:
`git -C <mothership> fetch` → Drift prüfen → veraltete Zeilen neu markieren.

> **Fokus-Ritual:** Fixpunkt (SHA) · Vergrößerung (Weitfeld → Struktur → granulare
> Oberfläche) · Journal-Eintrag (gepeilt / gesehen / Parallaxe für Mobile).

---

## Peilung vom 2026-07-03 — Sternposition `dababdb` (14:06)

**Branch:** `feat/mykilos8-block-d-provisioning` (Name irreführend „8", Inhalt = **V10**).
**Version:** `10.0.0-alpha` (alpha1→alpha4 an einem Tag). 226 Commits vor `main` (7.7.2).
**⚠️ Wichtig:** `main` und der ursprüngliche Mobile-Branch stehen auf **7.7.2 — veraltet**.
Die mitgelieferte CLAUDE.md redet sogar von 7.5. **Drei Stände Drift** — Lehre: immer fetchen.

### Was V10 (der Stern) ist
Ein Satz: **der echte Schneider-Auftrag läuft zum ersten Mal komplett durch mykilOS** —
Fragebogen → Kunde+Projekt → persistierter Warenkorb → ein Klick „Zum Angebot" →
MYKILOS-PDF-Vorschau → Cash-Zeile. Nordstern des Sterns: *minimal · functional · smart · beautiful.*

### Portier-Landkarte (Parallaxe: was der Satellit vom Kern erben könnte)

| Mothership-Target | Gewicht mobil | Beobachtung (`@dababdb`) |
|---|---|---|
| `MykilosKit` | ✅ Foundation-only | 0 AppKit → plattformneutral, teilbar |
| `MykilosKalkulationsCore` | ✅ Foundation-only | reiner Schätzkern → teilbar (aber schwere Rechnung bleibt oben) |
| `MykilosDesign` | 🟡 | 1 Stelle `NSColor` (`Tokens.swift:53`) → `UIColor`-Bridge |
| `MykilosServices` | 🟡 | GRDB läuft iOS. Blocker: OAuth (Loopback-TCP-Server + `NSWorkspace`) → mobil `ASWebAuthenticationSession` |
| `MykilosWidgets` | 🟡 | `DocumentViewerView` (PDFKit/QuickLook via `NSViewRepresentable`) → UIKit-Variante |
| `MykilosApp` | 🔴 | 13 AppKit-Dateien = macOS-Shell (Fenster/Dock/Single-Instance) → **eigene iOS-Shell, kein Port** |

**Deutung:** Der Foundation-Kern ist geschenkt; die Shell ist Neubau. Aber v0 braucht
*keinen* davon — v0 ist Claude + Connectoren. Der Kern-Port ist ein *späteres* Thema,
und wenn, dann als **einseitiger Lichtaustausch** (Mothership publiziert, Mobile konsumiert).

### Die Konstellation (reale Widgets `@dababdb`)
`Calendar · Cash · Contacts · Drive · Mail · Notes · Tasks · Warenkorb` + `WorkBasketEditSheet`
+ `AssistantChatView`. → Auf mobile **nicht spiegeln, sondern destillieren** auf ★2.

### Zarte Sterne (Backlog `IDEEN_UND_BACKLOG.md@dababdb`)
- „mykilOS fürs iPad" (Z. 191) — riet **iPad zuerst**, iPhone brauche echtes Redesign.
- „Boss Button als App-Satellit" (Z. 226) — **verworfen** (macOS-Gimmick).
- **Live-Beweis (Screenshots 03.07. 20:18):** Clockodo, Drive, Google Maps, Slack,
  ClickUp existieren als **native iPhone-Apps** → Grundlage der Dirigent-Doktrin.

### Frische Eiserne Regeln des Sterns (03.07., vorher unbekannt)
- **Aufgaben nur Mensch→Mensch, nie KI→Mensch** (systemweit).
- **Belegführung immer extern (sevDesk)** — mykilOS stellt NIE verbuchungspflichtige
  Dokumente aus; nur Warenkörbe + Postbox + Drive-Ordner. Angebots-PDF = *beschriftete Vorschau*.
- **Clockodo nie direkt schreiben** — private Postbox als Stundenprotokoll.

---

## Nächste Peilungen (offen)
- Hohe Vergrößerung auf ★1: Clockodo-Postbox-Architektur (Airtable-Tabellen liegen schon:
  `Clockodo-Nutzer`, `Clockodo-EW-<Name>`, `Clockodo-Buchungen`).
- Deep-Link-Fähigkeiten je nativer App (Hinspringen: Maps ✅, Drive ✅, ClickUp ✅, Slack ✅;
  Schreiben: begrenzt → Postbox).

---

## Peilung vom 2026-07-03 spät — autonome Session (Sternposition weiter `dababdb`)

### ★1-Volltreffer: Die Postbox existiert schon (neuer als der alte Kontext!)
`Sources/MykilosServices/Clockodo/ClockodoAdapterWriter.swift@dababdb`:
- Schreibt ein lokal **bestätigtes** `TimeSegment` (Karte→Bestätigung bereits erfolgt)
  als „Vorgebucht"-Zeile in die Adapter-Base **`mykilOS-Adapter Clockodo`**
  (`appuQDCFGLmjo2L6T`, Tabelle Zeitbuchungen `tbllYkxcHzI2YMUqn`). **Append-only.**
- Kommentar wörtlich: echter Clockodo-API-POST „**dauerhaft ausgeschlossen**" —
  die Airtable-Zeile ist die einzige Schreib-Eskalationsstufe; die tatsächliche
  Buchung bleibt manuelle Eigeneingabe des Nutzers in Clockodo.
- **Konsequenz für den Satelliten:** ★1 zielt auf DIESELBE Postbox mit DERSELBEN
  Semantik („Vorgebucht", append-only, ein Record pro Segment). Nichts Eigenes erfinden.
- Legacy daneben: die EW-Tabellen (`Clockodo-EW-*` in `appuVMh3KDfKw4OoQ`) stehen
  weiter in `PARTNER_APP_SCHEMA.md` (User-IDs: Johannes 421694, Jilliana 391140,
  Daniel 391057, Frauke 391141). Die Adapter-Base ist der neuere, freigegebene Pfad
  (Johannes, 2026-07-01). Bei Bau von ★1: kurz bestätigen lassen, welche gilt.

### Live-Beweis ① ausgeführt (Schmidt 2026-016) — siehe `prototypes/briefing-schmidt_2026-07-03.md`
- Registry-Git-Kopie (`docs/registry/*.json`) = perfekte Graph-Quelle für den Satelliten.
- Drive live: Kanon-Ordnerstruktur 01–09 + CAD + Präsentation, echte Deep-Link-URLs.
- **Design-Wahrheit gefunden: Freitext-Anker lügen** (Cosentino-Schmidt ≠ Projekt-Schmidt;
  Kommission „#Schmid" ist real falsch beschriftet und meint #Schneider). IDs > Namen.
- Airtable-Connector: Freigabe-Schranke (ein Klick von Johannes nötig, wenn gewünscht).
- Kalender-Connector live, für „Schmidt" leer. Gmail live.

### Epistemik-Regel „Milchstraße" (Johannes, 2026-07-03 spät)
- **★1-Ziel bestätigt: Adapter-Base** (`appuQDCFGLmjo2L6T` → Zeitbuchungen).
- **Airtable-Lesen: generell freigegeben.** ABER: Airtable ist bewusst weit gefächert,
  noch nicht sortiert — „Milchstraße und Sternenstaub", **keine Luther-Bibel.** Struktur
  kann sich ändern, wenn treffendere Lösungen gefunden werden.
- **Konsequenz für den Satelliten (verbindlich):** schema-tolerant lesen. Koppeln an
  BEDEUTUNG (Projektnummer, Ordner-ID, Status-Semantik wie „Vorgebucht"), nie an
  Tabellen-Layout/Feld-Anordnung. Layout-Drift darf den Satelliten nicht brechen —
  gleiche Lehre wie Codable im Mothership: additiv, tolerant, `decodeIfPresent`-Geist.
- Technisch: MCP-Connector-Schranke braucht noch Johannes' Freigabe-Klick in der UI.

### Peilung PROJEKTE-Root live (03.07. spät) — Registry-Drift + Puls
- **Ein Griff, alle Ordner:** Root-Listing liefert `modifiedTime` für alles. „Gerade
  heiß" heute: 2026_038 + 2026_037 (Berger, BEIDE HEUTE angelegt — Registry kennt sie
  nicht!), Doehle 00:30, HS-Architekten, Liebig, Schneider 01.07. spät.
- **Registry-Drift bewiesen:** Git-Kopie kennt 31 Projekte, Drive zeigt 36+ (027–029,
  037, 038 fehlen). → Verbindlich: **Registry = Graph (wer gehört zu wem),
  Drive = Puls (was lebt gerade).** Der Satellit mischt beide Quellen und sagt ehrlich,
  welche wie frisch ist.
- Am Root leben auch Nicht-Projekte (`_TEST_PROVISIONING`, `_BEISPIELORDNER…`,
  `_PROJEKTE_ARCHIV`, `HAMBURG`) → Unterstrich-Präfix + Namensparser filtern.
- Prototyp v2 publiziert: „Gerade heiß"-Zeile mit echten Zeiten, gleiche URL.
