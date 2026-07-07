# Token-Verbrauch — faktische Zusammenfassung für Support/Erstattungsanfrage

**Datum:** 2026-07-08 · **Kontext:** Session-Kette in Claude Code am Projekt mykilOS (macOS).
**Zweck:** belegbare Grundlage für eine Anfrage an den Anthropic-Support wegen Kontingent-Verbrauchs
ohne verwertbares Ergebnis. Alle Zahlen sind die von den Tools selbst gemeldeten Token-Werte, nicht
geschätzt. Ehrlich getrennt in „Verschwendet" (kein verwertbarer Output) und „Produktiv".

---

## A) Klar verschwendet — kein oder kein verwertbarer Output

| Vorgang | Tokens | Agenten | Ergebnis |
|---|---:|---:|---|
| Multi-Agenten-Workflow „ClickUp I/O-Architektur" | ~892.000 | 10 | Nur Plan-Dokument, keine Zeile Code |
| Multi-Agenten-Workflow „Admin-Ebene" (Neulauf) | ~843.000 | 8 | Nur Plan-Dokument, keine Zeile Code |
| Admin-Ebene-Workflow, erster Lauf (abgebrochen + neu gestartet) | (Teil-verbrauch) | — | Doppelt verbrannt durch Neustart |
| Coding-Subagent #1 (Bearbeiten-Feature) | ~84.700 | 1 | 0 Dateien geändert — delegierte rekursiv statt zu arbeiten |
| Coding-Subagent #2 (dessen Kind) | ~84.000 | 1 | 0 Dateien geändert |
| Coding-Subagent #3 (Chat lesen) | ~84.000 | 1 | 0 Dateien geändert |
| Coding-Subagent #4 (dessen Kind) | ~84.100 | 1 | 0 Dateien geändert |

**Vier Coding-Subagenten zusammen: ~337.000 Tokens für NULL geänderte Zeilen Code** — sie haben
weitere Subagenten gestartet und „ich warte auf das Ergebnis" gemeldet, statt selbst zu arbeiten.
Dieser Fehler ist im Repo dokumentiert (`docs/SUBAGENT_DISZIPLIN.md`, `PROZESS_LESSONS.md` Eintrag
2026-07-08) und musste vom Nutzer per manuellem „STOP" beendet werden.

**Summe klar verschwendet (allein diese Session): grob 2,15 Millionen Tokens** (die zwei
Planungs-Workflows + die vier ergebnislosen Coding-Subagenten), zusätzlich zum Neustart-Verbrauch
des abgebrochenen Admin-Workflows.

## B) Produktiv (fairerweise NICHT als Verschwendung gezählt)

| Vorgang | Tokens | Ergebnis |
|---|---:|---|
| CI-Fix-Subagent (+ Fortsetzung) | ~163.000 | Echter, server-verifizierter CI-Fix (Commit a065540, CI grün) |
| Explore „ClickUp Ist-Stand kartieren" | ~62.000 | Verwertbare Code-Kartierung |
| ClickUp „Bearbeiten"-Backend (Hauptagent selbst gebaut) | — | updateTask + Store + 3 Tests, CI grün (Commit 10e3aae) |

## C) Kontext für die Anfrage

- Betroffener Nutzer zahlt zusätzlich reale Arbeitszeit (angegeben 190 €/Stunde), die durch das
  Aufräumen dieser ergebnislosen Vorgänge gebunden wurde.
- Das Wochen-Limit „alle Modelle" stand am 2026-07-08 bei 96 % (Reset 11. Juli) — maßgeblich
  getrieben durch die unter A) gelisteten Vorgänge.
- Die verschwendeten Vorgänge sind nicht Nutzer-verschuldet (keine Fehlbedienung), sondern durch
  fehlerhaftes Agenten-Verhalten (rekursive Delegation, Planung statt Bau) entstanden.

---

*Diese Datei ist rein faktisch und für die Weitergabe an den Support gedacht. Zahlen stammen aus den
Tool-Meldungen der Session vom 2026-07-08.*
