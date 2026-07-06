# Handoff — Session-Abschluss 2026-06-28

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: stabilize/from-0b7c366-2026-06-28
Build:  ✅ swift build grün
Tests:  169 grün (swift test)
Datum:  2026-06-28
Agent:  Claude Code Desktop (claude-sonnet-4-6)
```

---

## Was diese Session gebracht hat

Diese Session war eine Stabilisierungs- und Orientierungs-Session nach einer Phase
paralleler Entwicklung in mehreren Worktrees und Branches.

### 1. Eiserne Regel eingeführt
`CLAUDE.md` hat jetzt einen `⛔ EISERNE REGEL`-Abschnitt ganz oben:
- Kanonischer Ordner ist und bleibt `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/`
- Pflichtchecks (`pwd`, `git branch`, `swift build && swift test`) vor jedem Handoff
- Handoff-Header-Pflicht (Pfad + Branch + Build + Tests + Datum)
- `~/Desktop/CLAUDE/` = temporäre Worktrees, nie dauerhafter Arbeitsort

### 2. Ereignisprotokoll angelegt
`docs/EREIGNISPROTOKOLL.md` — lebendes, chronologisches Protokoll aller Sessions.
**Pflicht für jeden Agenten:** bei jeder Session oben einen neuen Eintrag hinzufügen.
Enthält: Branch-Übersicht, offene Punkte, Airtable-Tabellen-IDs, Keychain-Service-Namen.

### 3. Airtable-Keychain-Bug behoben
Das Keychain-Feld `baseID` enthielt fälschlich einen zweiten PAT-Token.
Johannes hat in der App → Einstellungen → Airtable → `appuVMh3KDfKw4OoQ` eingetragen.
Airtable-API-Check: ✅ Kunden, Projekte, Clockodo-Nutzer, Clockodo-Leistungen erreichbar.

### 4. Vollständiger Verbindungscheck
| Service | Status |
|---|---|
| Airtable (PAT + Base-ID) | ✅ live |
| Claude API (claude-sonnet-4-6) | ✅ live |
| Google (OAuth-Token) | ✅ Keychain, in App prüfen |
| Clockodo (johannes@mykilos.com) | ✅ Keychain, in App prüfen |
| ClickUp (API-Key) | ✅ Keychain, in App prüfen |
| Sevdesk | NO-GO — nicht geprüft |

### 5. Memory vollständig aktualisiert
Alle relevanten Erkenntnisse sind in dauerhaften Memory-Dateien gesichert:
- `canonical-folder-rule.md` — Eiserne Regel
- `project-current-state.md` — App-Stand 6.3.0, Branches, offene Punkte
- `airtable-keychain-bug.md` — Bug + Behebung dokumentiert
- `mykilos-kalkulation-integration.md` — mykilO$$-Entscheidungen (bereits vorhanden)
- `external-data-no-gos.md` — NO-GOs (bereits vorhanden)

---

## Ehrlicher Ist-Stand (2026-06-28)

### Was live und vollständig funktioniert
- **App:** Version 6.3.0, build-clean, 169 Tests grün
- **Alle Sidebar-Module live:** Heute, Projekte, Assistent, Marken & Daten, Angebote, Einstellungen
- **Alle Projekt-Tabs live:** Assistent-Chat (scoped), Dateien (Drive), Angebote (Drive), Material
- **Onboarding-Wizard:** First-Run-Flow, ProfileStore, UserProfile im Assistent-Prompt
- **Konversationeller Assistent:** Multi-Turn-Chat, Streaming (SSE), Tool-Use (Gmail-Labels,
  Kalender, CalendarActionCard → Google Kalender im Browser öffnen ohne API-Write)
- **Integrationen (Widgets):** Drive, Kalender, Kontakte, Mail, ClickUp-Tasks, Cash (Sevdesk),
  Clockodo (Demo-Daten), Assistant-Widget (regelbasiert + Claude-Zusammenfassung)
- **Navigation:** Cmd+1..6, Favoriten klickbar (Heute → Projektdetail), WindowGuard (Drift-Fix)
- **Drive-Offer-Watcher:** Polling → offerDetected-Signal

### Was noch NICHT live / offen ist
| # | Was | Nächste Session |
|---|---|---|
| 1 | Google OAuth vollständig end-to-end verifizieren | manueller Beta-Check |
| 2 | Clockodo-Widget: echte Zeiten statt Demo-Daten | Live-Wiring 4 |
| 3 | Clockodo Zuhörer (Chat → Zeitbuchung → POST) | Live-Wiring 4 |
| 4 | mykilO$$ Kalkulations-Core portieren (10 Dateien) | Live-Wiring 5 / Session F |
| 5 | Airtable: Auto-Sync beim Start auf die richtigen Tabellen | prüfen nach Keychain-Fix |
| 6 | `sprint/shared-drive-widget-oauth`-Branch auf Regression prüfen | vor Merge |

---

## Branch-Situation

```
stabilize/from-0b7c366-2026-06-28   ← AKTIV, sauber, 169 Tests ✅
  └─ ad17a49 docs: Eiserne Regel + Ereignisprotokoll   (diese Session)
  └─ 130e6c0 docs: mark forensic recovery point        (Codex)
  └─ 0b7c366 docs: Destillation entschieden            (Basis)

sprint/shared-drive-widget-oauth     ← Feature-Branch, 169 Tests
  └─ enthält Session-Docs (4b3df08, 8c28443) + alle Live-Wiring-Features
  └─ ⚠️ vor Merge: swift build + swift test prüfen

main                                 ← veraltet (~97 Tests, Version 6.0.x)
  └─ noch nicht mit den Feature-Branches gemergt
```

**Empfehlung:** `stabilize/` und `sprint/shared-drive-widget-oauth` sichten,
dann in `main` mergen, bevor neue Feature-Arbeit beginnt.

---

## Startprompt für nächste Session (copy-paste)

```
Du übernimmst mykilOS 6 — macOS-Studio-Cockpit (SwiftUI, local-first, GRDB).

━━━ PFLICHT: ZUERST AUSFÜHREN ━━━
pwd
# Muss enden mit: /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac
git branch && git status
swift build && swift test 2>&1 | tail -5

Erst wenn Build + Tests grün sind, weitermachen.

━━━ DANN LESEN ━━━
docs/EREIGNISPROTOKOLL.md    ← neueste Einträge oben
CLAUDE.md (Abschnitt "EISERNE REGEL" + "Wo wir stehen")

━━━ AKTUELLER STAND ━━━
Version 6.3.0 · Branch stabilize/from-0b7c366-2026-06-28 · 169 Tests
Alle Module und Tabs live. Assistent mit Chat + Tool-Use.

━━━ NÄCHSTE AUFGABEN (wähle eine) ━━━
A) mykilO$$ Kalkulations-Core → docs/handoffs/CODEX_HANDOFF_KALKULATION.md
B) Clockodo Zuhörer        → docs/handoffs/HANDOFF_LIVE_WIRING_4.md

━━━ ABSOLUTE VERBOTE ━━━
• Sevdesk: nie lesen/schreiben
• Drive-Ordner 0AOeReQBQKkKBUk9PVA: read-only
• Airtable-Base appkPzoEiI5eSMkNK: nie anfassen (stillgelegt)
• Secrets nur Keychain, nie in Code/Commits/Logs
• Signale = VORSCHLÄGE → schreiben nur via ActionCard → Bestätigung → AuditEntry
• Neues persistentes Feature → Cold-Start-Test ist Merge-Gate
• MykilosKit: kein SwiftUI, kein GRDB | MykilosWidgets: kein GRDB

━━━ JEDE SESSION ENDET MIT ━━━
1. swift build + swift test grün
2. Neuer Eintrag oben in docs/EREIGNISPROTOKOLL.md
3. CLAUDE.md Status-Tabelle aktualisiert
4. Commit auf Feature-Branch (nie direkt main)
5. Kein Push ohne Johannes' Freigabe
```

**Modell-Empfehlung:** Opus + Aufwand high (für Kalkulations-Port und Clockodo-Architektur).
Sonnet + medium nur für UI-Polishing oder einfache Bugfixes.

---

## Wichtige Dateipfade

```
CLAUDE.md                                     ← Projektgedächtnis, Eiserne Regel oben
docs/EREIGNISPROTOKOLL.md                     ← Session-Protokoll (immer zuerst lesen)
docs/handoffs/HANDOFF_LIVE_WIRING_4.md        ← Clockodo Zuhörer Architektur
docs/handoffs/CODEX_HANDOFF_KALKULATION.md    ← mykilO$$ Port-Anleitung
docs/handoffs/HANDOFF_LIVE_WIRING_5.md        ← mykilO$$ Vollintegration Plan
docs/KALKULATION_INTEGRATION.md               ← 10 Schritte, GRDB-Migration, Tests
script/airtable_verify.sh                     ← Alle Airtable-Tabellen prüfen
script/build_and_run.sh                       ← App-Bundle bauen + starten
```

## Airtable-Mastermind (`appuVMh3KDfKw4OoQ`) — alle Live-Tabellen

| Tabelle | ID |
|---|---|
| Kunden | (per airtable_verify.sh ermitteln) |
| Projekte | (per airtable_verify.sh ermitteln) |
| Clockodo-Nutzer | `tblPbly2br8mR2kaU` |
| Clockodo-Buchungen | `tblYQxlauwej7FD1w` |
| Clockodo-Leistungen | `tblRtsegocdpM8CJd` |
| Kalkulationen | `tblO3y2jdmxDnuiZj` |
| Kalkulations-Positionen | `tblNamx3cHTus6gtk` |
| Eingehende-Angebote | `tbliKfs5FnufjdB36` |
