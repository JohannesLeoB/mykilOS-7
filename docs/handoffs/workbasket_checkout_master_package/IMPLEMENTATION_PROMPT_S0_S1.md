# Implementation Prompt S0 / S1

Verwende diesen Prompt fuer Claude Code oder Codex im Repo `JohannesLeoB/mykilOS-7`.

## Rolle

Du bist weiterfuehrender mykilOS Architekt. Die App hat Masterstatus. Du respektierst AppState, MainActor, bestehende UI/CI/UX, Review-first, Audit-first, local-first und alle bestehenden Handoffs.

## Auftrag

Starte nicht mit Feature-UI. Starte mit Wahrheit und I/O.

S0: System Truth Map.
S1: I/O Register und Integrationsmatrix.

## Vorher ausfuehren

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6"
pwd
git status
git branch --show-current
git branch -vv
git log --oneline --decorate -12
swift build
swift test
```

Wenn nicht sauber oder nicht gruen: stoppen und Handoff schreiben.

## S0 Deliverables

Lege oder aktualisiere:

```text
docs/SYSTEM_TRUTH_MAP.md
docs/INTEGRATION_MATRIX.md
docs/WRITE_SAFETY_POLICY.md
```

SYSTEM_TRUTH_MAP muss enthalten:

```text
aktueller Branch
HEAD
Build/Test Status
relevante Module
bestehende Integrationen
bestehende Store-Grenzen
bestehende Write-Pfade
bekannte Feature Flags
bekannte externe Systeme
bekannte No-Gos
```

INTEGRATION_MATRIX muss fuer Airtable, Drive, Gmail, Calendar, Clockodo, ClickUp, Assistant, CAD, Firefly und Sevdesk enthalten:

```text
System
aktueller Status
Scopes / Auth
read capabilities
write capabilities
verbotene capabilities
bekannte Tabellen/Ordner/Ziele
zustand der Tests
Live-Gate Status
```

WRITE_SAFETY_POLICY muss festlegen:

```text
welche Writes erlaubt sind
welche Writes blockiert sind
welche Writes Review brauchen
welche Writes Admin-Freigabe brauchen
welche Operationen niemals erlaubt sind
wie Incidents dokumentiert werden
```

## S1 Deliverables

Lege oder aktualisiere:

```text
docs/IO_REGISTER.md
docs/AIRTABLE_SCHEMA_WORKBASKET_CHECKOUT.md
docs/WORKBASKET_CHECKOUT_ARCHITECTURE.md
```

IO_REGISTER muss fuer jede geplante Aktion enthalten:

```text
IO-ID
Modul
Aktion
Quelle
Ziel
Operation
Trigger
Rolle
Preview Pflicht
Review Pflicht
Audit Pflicht
Fehlerfall
Testfall
Live-Gate
```

## Stop-Regel

Nach S0/S1 keinen Feature-Code anfangen, bevor Johannes oder Projektleitung den I/O-Stand akzeptiert.

## Commit-Regel

Commit nur docs. Commit Message:

```text
docs(workbasket): S0/S1 truth map and IO register
```

Handoff am Ende:

```text
Build:
Tests:
Neue Dateien:
Geaenderte Dateien:
Erkannte Writes:
Blockierte Writes:
Offene Fragen:
Naechster Schritt:
```
