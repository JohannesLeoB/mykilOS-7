# Brief · S4 — Provisioning-Bundle (Projekt-Geburt)

**Modell:** Opus 4.8 (Designpass: Mehrsystem-Orchestrierung, Idempotenz, Teilfehler) → Sonnet 4.6 (Implementierung) · **Gate:** ⚠️ **Johannes' Write-Gate-OK + ClickUp-Entscheidung** · **Abhängigkeit:** S2 + S3 · **Schreibt extern:** JA (mehrere Systeme).

## Auftrag
Eine einzige bestätigte Karte lässt ein neues Projekt in mehreren Systemen gleichzeitig „geboren" werden.

## Umfang (eine Karte → ein Audit-Eintrag)
1. **Airtable:** neuer Projekt-Datensatz (Kdnr, Token, Projektnummer) — Schreiben ins SoR.
2. **Drive:** Ordnerstruktur nach Konvention.
3. **Clockodo:** neues Projekt unter dem passenden Kunden, alle Mitarbeiter buchungsberechtigt.
4. **Clockodo-Services:** die projektabhängigen Kostenstellen (aus Airtable) als Services anlegen — sonst läuft der S3-Upload beim ersten Mal ins Leere.
5. *(optional, nur falls ClickUp-Weg gewählt:)* ClickUp-Task mit Template + vorbefüllten Feldern.

## Eigenschaften
- **Idempotent** (Schlüssel: Kdnr + Projektnummer) — re-runnable ohne Duplikate.
- **Teilfehler-fest:** schlägt Schritt 3 fehl, dürfen 1–2 nicht in inkonsistentem Zustand zurückbleiben; klare Wiederaufnahme.
- **Jeder Schritt wirft**, die Gesamtaktion ist eine bestätigte, auditierte Karte.

## Tests (Pflicht)
Idempotenz (zweiter Lauf erzeugt nichts Neues); Teilfehler hinterlässt definierten Zustand + Wiederaufnahme; jeder Schritt wirft bei Fehler; Audit vollständig.

## Hinweis
Vor dem Bau steht Johannes' Write-Gate-OK **und** die ClickUp-Entscheidung (ob Schritt 5 dazugehört). Ohne beides: nicht bauen, nachfragen.
