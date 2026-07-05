# 🌳 HANDOFF — 11.0.0 auf main konsolidiert (2026-07-05, spät)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/kamera-barcode-widget  (== origin, == origin/main nach Merge)
main:   ✅ konsolidiert — PR #4 gemergt (Merge-Commit 2b3be7b)
Build:  ✅ swift build grün · Tests ✅ 1052 grün · CI ✅ GRÜN (macos-15)
Safe:   ✅ Tag v7.0.0 (e629e84) unangetastet — Rückfallebene
DMG:    dist/mykilOS-11.0.0.dmg (raus aus Alpha, erste ship-fähige Version)
Datum:  2026-07-05 (spät)
```

## Was diese Session erreicht hat
**Orphan-Rebind A–D** (Personalausweis fertig: Rebind nach Google-Login + Keychain-Anker + suffixloser „letzte Mail"-Slot + Claude-`.local`-Fix) · **Schlüssel-Inventar** (read-only Zugangs-Übersicht) · **Mini-Mode-Fix** (Mouseover raus, Klick öffnet App) · **UI-Fixes** (Wortmarke größer, Assistent-Kopieren ohne Zittern) · **Drive-Sync konsolidiert** (ein Befehl in Settings→Integrationen→Google, verstreute Leisten raus — Parent-I/O) · **Settings-Ebene Etappe 1** (Integrationen-Rename + privat→geteilt-Reihenfolge) · **zwei Ultracode-Planungen** (Settings-Ebene + Bewohner-Oberfläche) · **Handgepäck-Audit** (App reist sauber) · **Version 11.0.0** · **PR #4 → main gemergt**.

## 🔧 Die CI-Sanierung (war seit langem rot, jetzt grün — 3 versteckte Schichten)
1. **Lint-Alt-Schuld** (1787 Verstöße, ganze Codebase) → `swiftlint-baseline.json` eingefroren; **Pfade auf CI-Checkout umgeschrieben** (SwiftLint speichert absolute `file://`-Pfade — lokal ≠ CI). ⚠️ Tech-Debt: Baseline händisch pfad-gepinnt.
2. **Compiler-Crash** auf `macos-14` → Runner auf **`macos-15`** gehoben.
3. **Umgebungsabhängige Tests** (Zeitzone/Locale) → CI-`env: TZ=Europe/Berlin, LC_ALL=de_DE.UTF-8`. ⚠️ Band-Aid — sauberer wären umgebungsunabhängige Tests.

## 📋 Nächste Stränge (die frische Session nimmt einen davon)
1. **🎨 Logos (Sidequest, Johannes-Wunsch, klein–mittel):** neue klassische „M"-Icons liegen in `docs/design/logos/` (`…-ink.svg` = dunkel, `…-paper.svg` = hell). **(a)** neues App-Icon einbauen (alle Dock-Größen, `.icns` + `build_and_run.sh`/`create_dmg.sh` ziehen es), **(b)** **Hell/Dunkel-Dock-Wechsel**: App erkennt `NSApp.effectiveAppearance` → setzt `NSApp.applicationIconImage` auf Ink (Dunkel) bzw. Paper (Hell), auf Appearance-Änderung umschalten.
2. **🗄️ Korpus → Team-Airtables, KOMPLETT (groß, Johannes-Priorität, Write-GO gegeben):** alle Korpus-Daten UND Logik in die Team-Airtables (`appuVMh3KDfKw4OoQ`) — volle Parität für Teammitglieder (Admin-/Sichtbarkeits-Feinsteuerung SPÄTER). **Achtung:** es gibt KEINE fertige `Preis-Beobachtungen`-Tabelle; nächste ist `Eingehende-Angebote` (`tbliKfs5FnufjdB36`, Dokument-Ebene). → Schema entwerfen (Beobachtungen/Anker/Positionen), Import (Dedup SHA256), Sync-Pfad (Airtable=Wahrheit, `learning.sqlite`=Cache), **Datenstrom-Handbuch-Eintrag** (`tblaUVftka0GvXzeU`) + `DataFlowLogger`-ID. Ultracode-planbar. Quelle: [[kalkulation-datenbestand]], [[parent-io-ordnungsprinzip]].
3. **🏠 Bewohner-Oberfläche Etappe 2+** (Personalausweis-Header etc.) — Plan: `plaene-2026-07-05/BEWOHNER_OBERFLAECHE_PLAN.md`. Etappe 1 (Rename+Order) ✅ erledigt.
4. **🧹 Qualitäts-Schuld:** Lint-Cleanup (1787 abtragen + Baseline sauber neu generieren), umgebungsunabhängige Tests (TZ/Locale-Band-Aid ersetzen).

## Durable Pläne (alle in `docs/handoffs/plaene-2026-07-05/`)
`SETTINGS_EBENE_PLAN.md` · `BEWOHNER_OBERFLAECHE_PLAN.md` · `ORPHAN_REBIND_PLAN.md` · `HANDGEPAECK_AUDIT.md`

## Startprompt nächste Session
> Lies MEMORY.md + [[session-stand-2026-07-05-checkin]] + diesen Handoff. Pflichtprüfung (`pwd`, `git status`, `swift build && swift test`). Dann: Logos (Sidequest) ODER Korpus→Airtable (groß) — Johannes' Wahl. Bei Korpus zuerst Ultracode-Planung + Datenstrom-Handbuch, dann Bau. Nichts auf main ohne PR+GO+CI-grün.
