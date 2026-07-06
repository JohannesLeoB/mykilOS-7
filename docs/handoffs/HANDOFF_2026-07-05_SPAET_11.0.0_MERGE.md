# 🌳 MASTER-HANDOFF — 11.0.0 auf main + nahtloser Übergang (2026-07-05, spät)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/kamera-barcode-widget  (== origin)
main:   ✅ 11.0.0 konsolidiert (PR #4, Merge-Commit 2b3be7b) — ABER feat ist +6 voraus (s.u.)
Build:  ✅ swift build grün · Tests ✅ 1052 grün · CI ✅ GRÜN (macos-15)
Safe:   ✅ Tag v7.0.0 (e629e84) unantastbar — Rückfallebene
DMG:    dist/mykilOS-11.0.0.dmg (ship-fähig, inkl. Dock-Icon)
Datum:  2026-07-05 spät · nächste Session evtl. anderer Claude-Account (Repo+Memory kommen mit, Chat NICHT)
```

> **👉 Für die nächste Session: DIES lesen + `MEMORY.md` (Index) + [[session-stand-2026-07-05-checkin]]
> + [[zusammenarbeits-charter]] (wie wir arbeiten) + `docs/erfahrungstraeger/PROZESS_LESSONS.md`
> (Meta/Zusammenarbeit). Dann Pflichtprüfung (`pwd`, `git status`, `swift build && swift test`).**

---

## 0. In 30 Sekunden
`main` ist **11.0.0** (raus aus Alpha), sauber konsolidiert, CI **zum ersten Mal wirklich grün**,
Safe State intakt, alles offsite. Heute gebaut: Orphan-Rebind A–D, Schlüssel-Inventar, Mini-Mode-Fix,
UI-Fixes, Drive-Sync-Bündelung, Settings-Etappe-1, Dock-Icon Hell/Dunkel. Zwei große Pläne fertig
(Bewohner-Oberfläche, Korpus→Airtable). **Nichts brennt.**

## 1. ✅ Erledigt diese Session
- **Orphan-Rebind A–D** — Personalausweis fertig: Rebind nach Google-Login + Keychain-Anker +
  suffixloser „letzte Mail"-Slot (schließt db-Reset-Verwaisung, gleicher Mac) + Claude-`.local`-Fix.
- **Schlüssel-Inventar** — read-only Übersicht aller 6 Zugänge (Status · persönlich/geteilt · verwaist), nie ein Secret.
- **Mini-Mode-Fix** — Mouseover-Flyout raus, Klick auf Satellit öffnet App (tote Karte gelöscht).
- **UI-Fixes** — MYKILOS-Wortmarke größer, Assistent-Kopieren ohne Zittern.
- **Drive-Sync konsolidiert** — EIN globaler Sync in Settings→Integrationen→Google, verstreute „Jetzt prüfen"-Leisten raus (Parent-I/O).
- **Settings-Ebene Etappe 1** — „Verbindungen"→„Integrationen", privat→geteilt-Reihenfolge.
- **Dock-Icon Hell/Dunkel** — neues MYKILOS-„M" (Ink/Paper), live bei System-Umschaltung (`DockIconController.swift`).
- **CI-Sanierung (3 Schichten)** — Lint-Baseline (auf CI-Pfad gepinnt), macos-15-Runner, TZ/Locale-env.
- **PR #4 → main gemergt** (110 Commits, 11.0.0).
- **Zwei Ultracode-Pläne + Handgepäck-Audit + Bewohner-Readiness ehrlich auditiert.**

## 2. 🔴 EHRLICH: Verschoben · Entglitten · Vergessen
**Große geplante, aber NICHT gebaute Stränge (Pläne liegen bereit):**
- **Korpus → Team-Airtable KOMPLETT** — geplant (`KORPUS_AIRTABLE_PLAN.md`), Johannes-Write-GO **da**,
  aber NICHT ausgeführt (context-schwer). Import-Skript + Datenstrom-Handbuch fehlen noch. **Der große nächste.**
- **Bewohner-Oberfläche Etappe 2–6** (`BEWOHNER_OBERFLAECHE_PLAN.md`): Personalausweis-Header (E2),
  Bänder+Store (E3), Meldeadresse im Wizard (E4, braucht Airtable-Write-GO), Multi-User (E5/6).
- **Farb-Picker** (Rainbow-Mode / eigene Ansichtsfarbe) — Johannes-Wunsch, bewusst „später".
- **Statisches App-Icon** neu backen — braucht SVG-Rasterizer (`brew install librsvg` → `rsvg-convert`); heute fehlte er.
- **Geräte-Katalog** (`Devices/catalog.csv`, 5.566 Artikel) → Airtable? Offene Entscheidung (Daniel-nah).
- **Multi-User auf einem Gerät** — als gewünschte Option vorgemerkt (`IDEEN_UND_BACKLOG.md`, Etappe 5/6).

**Qualitäts-/Prozess-Schuld:**
- **Lint-Alt-Schuld 1787** — baselined, nicht abgetragen (eigener Cleanup-Strang). ⚠️ **Gotcha:** Edit an
  einer schon-zu-langen Datei (`file_length`) verschiebt den Verstoß → CI rot → Baseline neu generieren
  + Pfade re-pinnen (Python-Replace `johannesleoberger…/mykilOS Mac/`→`runner/work/mykilOS-macOS/mykilOS-macOS/`, escaped `\/`; `sed` scheitert an 1-MB-Zeile).
- **Umgebungsabhängige Tests** (Zeitzone/Locale) — per CI-`env` gepflastert, nicht deterministisch gemacht.
- **`maxChars=6000`-Truncation-Bug** im Kalkulations-Import-Brief — vor echtem PDF-Live-Import fixen (Quelle: `IMPORT_BRIEF_VERIFIZIERT.md`).
- **Airtable-Enrich-Weiche** (Personalausweis) nicht im Datenstrom-Handbuch (früher durchgerutscht).
- **M-Liste** (CLAUDE.md): Google Re-Consent, Clockodo-Stundensätze in Airtable, ClickUp-Listen-IDs, sevdeskRef+Budget.
- **3 Schema-Generationen** des Korpus auf der Platte (v0.3/v4/brandless) — v0.3 mal als „historisch" labeln.
- **Flaky-Sub-Erfahrung:** ein Sonnet-Sub-Auftrag spawnte rekursiv sich selbst (Budget verbrannt) → für context-schwere Inventare lieber selbst gezieltes Bash.

**Konsolidierungs-Rest:**
- **`main` ist 6 Commits hinter `feat`** (Dock-Icon + Seal-Docs). Offsite sicher, aber für einen sauberen
  Stamm: **per PR nach main mergen** (GO + CI-grün). Erster kleiner Zug nächste Session — ODER jetzt auf GO.

**Bewusst geklärt (kein To-do):** Time Machine (Johannes: iCloud reicht erstmal) · Export-Strang der
Daten offsite (geparkt, learning.sqlite lokal).

## 3. Nächste Schritte — konkret & geordnet
1. **`main` glattziehen** (klein): PR feat→main für die 6 Commits (Dock-Icon + Docs) → main = voll aktuell.
2. **🗄️ Korpus → Team-Airtable** (groß, Johannes-Prio, GO da): Plan ausführen — Tabellen anlegen (MCP),
   dann Massen-Import per lokalem PAT/curl-Skript (append-only, idempotent via natürliche Keys + SHA256,
   gedrosselt), Sync-Pfad (Airtable→learning.sqlite), **Datenstrom-Handbuch-Weichen** `KORPUS_IMPORT`+`KORPUS_SYNC`.
   4 offene Entscheidungen im Plan (Umfang/Werkzeug/money_observations/Geräte-Katalog).
3. **🎨 Sichtbare Politur**: statisches App-Icon (librsvg) · Farb-Picker (Achtung Lint-Token-Regel bei Color(hex)) · Personalausweis-Header (E2).
4. **🧹 Qualität**: Lint-Cleanup + umgebungsunabhängige Tests (Root-Fix der CI-Band-Aids).

## 4. Durable Pläne (alle in `docs/handoffs/plaene-2026-07-05/`)
`KORPUS_AIRTABLE_PLAN.md` · `BEWOHNER_OBERFLAECHE_PLAN.md` · `SETTINGS_EBENE_PLAN.md` ·
`ORPHAN_REBIND_PLAN.md` · `HANDGEPAECK_AUDIT.md`

## 5. Startprompt (nächste Session, ggf. neuer Account)
> Moin! Lies `MEMORY.md`, diesen Handoff, `PROZESS_LESSONS.md` (letzter Eintrag = wie wir arbeiten) und
> das Gästebuch. Pflichtprüfung `pwd`/`git status`/`swift build && swift test`. Dann Johannes fragen:
> `main` glattziehen + **Korpus→Airtable** (der große, geplante, GO-freie bis auf den Write der da ist) —
> oder Politur (Icon/Farb-Picker/Personalausweis-Header)? Bei Korpus: Plan folgen, Datenstrom-Handbuch
> mitziehen, append-only. Nichts auf `main` ohne PR+GO+CI-grün. Torwächter: eigenes build/test/CI, nie
> „completed"/Diagnostics blind glauben. Kontextfenster aktiv im Blick (echter Tacho > Bauch).

*Sauberer Schnitt. Fester Sattel, festes Ziel, gewusst wie. Der Stamm steht. 🌳🫡*
