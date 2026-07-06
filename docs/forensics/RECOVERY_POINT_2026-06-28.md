# Forensischer Wiederherstellungspunkt — 2026-06-28

**Status:** Letzter nachgewiesen stabiler Ausgangspunkt, noch keine
Release-Freigabe.

**Angelegt:** 2026-06-28 03:17:19 +0200

## Verbindliche Identität

- Kanonisches Repository:
  `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac`
- Ursprünglicher Entwicklungszweig:
  `sprint/shared-drive-widget-oauth`
- Letzter nachgewiesen stabiler Commit:
  `0b7c3661edd27f1023c5f7d12ccb858aadab75d7`
- Letzter tatsächlicher App-Code-Commit innerhalb dieses Standes:
  `786f145`
- Erster als fehlerhaft nachgewiesener Sammel-Sync:
  `4b3df082599bb89b54b104fde703e44dcbbc326b`
- Späterer Dokumentationscommit auf dem beschädigten Zweig:
  `8c284438b7971f4ca6e6fd6ad72b11fa3d25a611`

## Git-Anker

- Unbeweglicher, annotierter Tag:
  `mykilos6-last-known-good-2026-06-28-013028`
- Baseline-Branch, die unverändert auf dem Beweisstand bleiben soll:
  `forensic/0b7c366-last-known-good`
- Reversibler Arbeitszweig für die Stabilisierung:
  `stabilize/from-0b7c366-2026-06-28`

Der ursprüngliche Sprint-Zweig bleibt vollständig erhalten. Es wurde kein
Reset, Rebase, Force-Push oder Löschen durchgeführt.

## Was bewiesen ist

- `swift build --disable-sandbox` war erfolgreich.
- `swift test --disable-sandbox` war erfolgreich:
  169 Tests in 27 Suites, keine Fehler.
- Der App-Code in `0b7c366` entspricht dem Code-Stand `786f145`; die Commits
  dazwischen betreffen Dokumentation.
- Die vom Benutzer bestätigten Screenshots sind die visuelle Referenz für die
  weitere Stabilisierung.

## Was ausdrücklich noch nicht bewiesen ist

- Der Stand ist noch nicht als Release freigegeben.
- Eine vollständige Live-Tour genau dieses Snapshots wurde während der
  forensischen Untersuchung noch nicht durchgeführt.
- Google OAuth, Drive-Feeds und Airtable Mastermind wurden für diesen Snapshot
  noch nicht gemeinsam Ende-zu-Ende abgenommen.
- Handoff-Dokumente waren teilweise weiter als der stabile Code.
- Die parallelen Commits `c4eef55`, `2bb14a9` und `89ee341` gehören nicht zur
  Historie dieses stabilen Ausgangspunkts. Sie dürfen nicht ungeprüft
  übernommen werden.

## Arbeitsvertrag ab diesem Punkt

1. Keine Sammel-Synchronisation und kein blindes Cherry-Pick paralleler
   Entwicklungszweige.
2. Jede Änderung bleibt klein, fachlich abgegrenzt und erhält einen eigenen
   Commit.
3. Vor jeder Änderung: Pfad, Branch und sauberer Arbeitsbaum prüfen.
4. Nach jeder Änderung: Build und relevante Tests ausführen; die Baseline sind
   169 grüne Tests.
5. Externe Schreibvorgänge bleiben bestätigungs- und auditpflichtig.
6. Wenn ein Schritt unsicher ist, wird er zuerst untersucht und dokumentiert,
   nicht durch Vermutung ersetzt.
7. Der Tag und die Baseline-Branch werden nicht verschoben oder überschrieben.

## Wiederherstellung

Exakten Beweisstand ansehen:

```bash
git switch --detach mykilos6-last-known-good-2026-06-28-013028
```

Zur unveränderten Baseline wechseln:

```bash
git switch forensic/0b7c366-last-known-good
```

Auf dem dokumentierten Stabilisierungszweig weiterarbeiten:

```bash
git switch stabilize/from-0b7c366-2026-06-28
```

Der nächste zulässige Schritt ist eine Live-Abnahme dieses Stands. Erst danach
werden einzelne, bereits vorhandene Änderungen aus parallelen Zweigen
verglichen und bei nachgewiesenem Nutzen manuell übertragen.
