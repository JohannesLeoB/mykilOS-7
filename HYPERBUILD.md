# 🜂 mykilOS 6+ Hyperbuild — Der Brühwürfel

> **Die ganze App auf einer Seite. Bei Session-Start ZUERST lesen — danach erst Code.**
> Wenn alles andere verloren ginge, ließe sich aus dieser Seite das Verständnis
> rekonstruieren. Jede Zeile trägt. Kein Ballast.

```
Pfad:    /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch:  polish/dampflok   ·   HEAD b5d062a   ·   GitHub JohannesLeoB/mykilOS-6 (privat)
Build:   ✅ swift build grün        Tests: ✅ 386 grün (62 Suites)
Modell:  claude-sonnet-4-6 (App, v6.5.0)   Stand: 2026-06-29 (Roadmap code-komplett, am Hustadt-Gate)
Fallback: git checkout ui/sidebar-ci-stable
```

---

## 1 · Was es ist

Ein persönliches macOS-Cockpit (SwiftUI, local-first) für Studio-Projektarbeit.
Jeder Nutzer sieht durch **seine** Identität auf **geteilte** Instrumente (Drive,
Kalender, ClickUp, Airtable) und **private** Daten (Clockodo). Farbe ist Sprache:
man erkennt die Quelle, bevor man liest. Airtable ist System-of-Record, kein
Sync-Backend. Signale sind Vorschläge — geschrieben wird nie ohne Bestätigung.

**Hyperbuild = mykilOS 6, das endlich *tut* was es behauptet.** Der Sprung ist
nicht „neue Features", sondern *Proof-of-Existence → Proof-of-Function* (siehe §3+4).

---

## 2 · Architektur in sieben Zeilen (das zeitlose Skelett)

```
App → Widgets → Design        |  Services → Kit        |  Integrations → Kit
MykilosKit       importiert NIE SwiftUI/GRDB (reine Domain + Persistence + Signals)
MykilosWidgets   importiert NIE GRDB; Widgets reden NIE direkt → nur StudioContext.emit()
Schreibvorgänge  kommen NIE aus Views — nur über Stores; jeder Write throws; SaveState sichtbar
Persistenz       GRDB; Cold-Start-Test Pflicht (schreiben→neue Instanz→lesen→identisch)
Tokens           SwiftLint erzwingt: Font.myk… / MykColor.… — keine .system()/Color(red:)
Secrets          nur Keychain, pro Nutzer isoliert; Clockodo nur Private Area
```

---

## 3 · Die eine Lektion (Wurzel aller 13 Forensik-Befunde)

> **Proxy-Optimierung statt Ziel-Optimierung.**

Frühere Sessions optimierten messbare Stellvertreter — Tests grün ✅, Ledger-Haken ✅,
Commit ✅, Handoff ✅ — und verwechselten sie mit dem Ziel: *läuft live, mit echten
Daten, am echten Gerät.* „Drive live" hieß „API antwortet", nicht „Nutzer öffnet Datei".
Ein Fehler, aufgeteilt in 13 Befunde (Forensik: 60 Agenten).
Vollständig: [docs/handoffs/HANDOFF_POLISH_DAMPFLOK.md](docs/handoffs/HANDOFF_POLISH_DAMPFLOK.md).

---

## 4 · „Fertig" = das Hustadt-Live-Gate (nicht grüne Tests)

```
Projekt Hustadt · driveFolderID 13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S
✅ Dateien-Tab zeigt Dateien aus lokalem Finder-Pfad
✅ PDF-Klick öffnet Vorschau — NICHT Safari
✅ Angebote-Tab findet PDF in „05 eingehende Angebote/Vorplanung…"
✅ Schaltzentrum: GMAIL_SEARCH > 0 Handshakes nach erstem Chat
✅ Settings → Diagnose: Version + Commit sichtbar
```
Drive/Offers/Assistent-Commits brauchen einen Hustadt-Haken im Handoff vor dem Merge.

---

## 5 · Wo wir stehen (die Wahrheit)

**Roadmap code-komplett.** Polish L1–L30 ✅ · Core Repair A–G ✅ (im Code verifiziert:
`LocalDriveRootResolver` löst echt über xattr lokal auf · `ConversationEngine` loggt
`manifestID(forTool:)` · `DiagnosticsReport` mit echtem Commit · `DocumentViewerView`
QuickLook/PDFKit · kein `try!` mehr) · Assistenten-Schreibtools S1–S17 ✅
([Ledger Block 10/11](docs/POLISH_LOOP_LEDGER.md)). S17 = 16-Agenten-Audit, 0 Defekte.

**Der einzige verbleibende Schritt ist LIVE — kein Code:** das Hustadt-Gate (§4) am
echten Gerät bestätigen. Drei code-fertige Features sind bis dahin inaktiv, weil sie
neue OAuth-Scopes brauchen → **M2 Google Re-Consent** (siehe §6).

---

## 6 · Die einzige To-do-Liste

**🔴 LIVE-ABNAHME (nur Johannes — der kritische Pfad zu „mykilOS 7.5"):**
1. **M2 Google Re-Consent** — Settings → Google **Trennen → Verbinden** (echtes Re-Consent,
   nicht nur Token-Refresh). Holt `drive.readonly` (Datei-Inhalt/Vorschau S3/S5),
   `contacts` (`create_contact` S9), `gmail.compose` (`create_draft` S14).
2. **M1 Airtable Base-ID fixen** (Settings → Airtable: `appuVMh3KDfKw4OoQ` statt PAT) 🔴 Sync-Blocker.
3. **Hustadt-Gate (§4) durchklicken** — die 5 Häkchen am echten Gerät.

**Core Repair A–G ✅ code-komplett** (im Code verifiziert, siehe §5). **Polish L1–L30 ✅.**

**🟢 Weitere manuelle Daten (Johannes, schalten Features scharf):**
M3 ClickUp-Listen-IDs (`list_all_clickup_tasks`) · M4 sevdeskRef+Budget · M5 Clockodo-Stundensätze ·
M6 Alt-PAT revoken · M7 `2026_20`→`2026_020`

**⚪ Optionaler nächster Code-Schritt (nicht M2-blockiert, auf Ansage):**
Voller Postfach-Sync `GmailSyncService` (über den TTL-Cache hinaus) — einziger größerer
Folgeschritt im Ledger (S12). Erst auf ausdrückliche Freigabe bauen.

---

## 7 · Eiserne Regeln

1. **Kanonischer Ordner** `…/MYKILOS 6/mykilOS6/`. `~/Desktop/CLAUDE/` = Wegwerf-Worktrees.
2. **Vor jedem Handoff:** `swift build && swift test` grün · `git status` clean.
3. **Externe Daten heilig:** Sevdesk nie · geteilte Airtable-Base & Drive-Root read-only · **nie löschen/überschreiben** (Inaktivierung nur per Status-Feld).
4. **„Fertig" = Hustadt-Gate.** **Push/PR nur auf ausdrückliche Freigabe.**
5. **Jede neue Daten-Weiche sofort** ins Datenstrom-Handbuch (Airtable `tblaUVftka0GvXzeU`) + `docs/BENUTZERHANDBUCH.md`.

---

## 8 · Karte (wo der Rest liegt)

- **Vollständiges Gedächtnis** → [CLAUDE.md](CLAUDE.md) · **Backlog/Ideen** → [docs/IDEEN_UND_BACKLOG.md](docs/IDEEN_UND_BACKLOG.md)
- **Verlauf (Pflicht-Mitschrift)** → [docs/EREIGNISPROTOKOLL.md](docs/EREIGNISPROTOKOLL.md) · **Nutzerfunktionen** → [docs/BENUTZERHANDBUCH.md](docs/BENUTZERHANDBUCH.md)
- **Daten-Schemata** → [docs/PARTNER_APP_SCHEMA.md](docs/PARTNER_APP_SCHEMA.md) · [docs/SCHALTZENTRUM_DATENSTROM.md](docs/SCHALTZENTRUM_DATENSTROM.md)
- **Team/Collective** → [docs/MYKILOS_6_TEAM_MODELL.md](docs/MYKILOS_6_TEAM_MODELL.md) · [docs/TEAM_CHARTER.md](docs/TEAM_CHARTER.md) · [docs/COLLECTIVE_REGELWERK.md](docs/COLLECTIVE_REGELWERK.md)
- **Historie komprimiert** → [docs/handoffs/_archiv/INDEX.md](docs/handoffs/_archiv/INDEX.md) · [docs/_archiv/](docs/_archiv/)

_Destilliert 2026-06-29 — der Brühwürfel. Wird mit jedem Meilenstein nachgeschärft, nie aufgebläht._
</content>
