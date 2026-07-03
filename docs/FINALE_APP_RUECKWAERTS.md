# mykilOS — Rückwärts gedacht (Finale-App-Radar)

Lebendes Dokument. Vom **fertigen** all-day-Cockpit her gedacht: was fehlt, was brauchen wir,
was ausbauen — bevor es weh tut. Ich (Claude) führe das laufend mit, unabhängig vom Sprint.

## Endzustand (Definition von „fertig")
Die eine App, aus der ein Küchen-/Interior-Studio den ganzen Tag **nicht mehr raus muss**:
sehen (alle Projekte/Quellen), **handeln** (Mail/Termin/Zeit/Angebot direkt), **zusammenstellen**
(Warenkorb→Port→Output), **verstehen** (KPIs/Forecast/Marge), **entscheiden** (Assistent proaktiv).
Schön, schnell, stabil, trickreich — local-first, Karte→Bestätigung→Audit, „Farbe ist Sprache".

## Rückwärts-Lücken (noch NICHT im Plan — beim Bauen mitnehmen)
- **Benachrichtigungs-Zentrum:** ein kohärenter Ort für ClickUp-Alerts, Deadlines, neue Angebote,
  Mail — statt verstreuter Signale. („Was braucht heute meine Aufmerksamkeit?" proaktiv.)
- **Volltext-Suche über ALLES** (⌘K springt heute nur zu Projekten/Bereichen) — Mails, Dateien,
  Notizen, Aufgaben, Angebote inhaltlich durchsuchbar.
- **Undo/Reversibilität** bestätigter Aktionen (Audit ist da — aber „rückgängig"?).
- **Templates** (Projekt/Task/Warenkorb/Dokument) — den Studio-Prozess kodieren, nicht neu tippen.
- **Kontakt-/Beziehungsintelligenz** (wer gehört zu welchem Projekt/Angebot; 371 Kontakte ohne Mail).
- **Performance @ Scale** bewusst prüfen (400 Projekte, 13k Artikel, 299 Belege) — Listen/Suche/Board.
- **Eine Datenwahrheit:** Airtable-Core vs. Artikel-DB entkoppeln/konsolidieren (Doppel-Identität Kunden/Projekte).
- **Client-facing:** Moodboard/Angebot-PDF sind Ports — später ein Freigabe-/Portal-Link für Kunden.
- **Multi-Window / zwei Projekte nebeneinander** (Power-User).
- **Tastatur-first überall** (nicht nur ⌘K) — Speed-Versprechen einlösen.
- **Accessibility/VoiceOver** systematisch (heute punktuell).

## Beobachten-Radar (Drift-Warnungen beim Bauen)
- **CI-Drift:** system-blaue Controls (Mail-Toggle-Bug) → überall auf mykilOS-Tokens prüfen, kein Default-Blau.
- **Kein Artikel-only-Hardwiring** im Warenkorb (Wirbelsäule-Generalisierung nicht verbauen).
- **Per-User-Isolation** bei allem Personenbezogenen (Clockodo/ClickUp/Rechte) konsequent.
- **S10 nicht umgehen:** Ports NICHT als Einzel-Features bauen, bevor die Pipeline entschieden ist.
- **Persistenz nie brechen** (GRDB-Migration nur anhängen) — Cold-Start-Tests.
- **Live-Abnahme-Schuld:** zu viel „code-fertig, nicht abgenommen" — S1 nicht ewig schieben.
- **Leere/Lade/Fehler-Zustände** wirklich überall (nicht nur in Widgets).

## Pflege
Neue Lücken/Beobachtungen hier ergänzen. Reife Punkte wandern in den Orchestrierungs-Plan bzw.
IDEEN_UND_BACKLOG. Vor jedem größeren Strang: diese Liste kurz gegenlesen.
