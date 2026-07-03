# Brief · S3 — Persönlicher Clockodo-Upload

**Modell:** Sonnet 4.6, high thinking · **Gate:** ⚠️ **Johannes' Write-Gate-OK nötig** · **Abhängigkeit:** S1 + S2 · **Schreibt extern:** JA (erster externer Write).

## Auftrag
Der „Hochladen"-Knopf sendet die lokal gebuchten Zeit-Segmente an Clockodo — als persönliche Übergabe, nicht als app-weiter Service-Write.

## Umfang
- Jeder Mitarbeiter hinterlegt seinen **eigenen** Clockodo-API-Key in der **eigenen Keychain**. Kein zentraler, app-weiter Schlüssel.
- Upload schreibt mit den Zugangsdaten der Person, **wirft** bei Fehlern (kein stilles Schlucken), wird **lokal auditiert**.
- Vor dem Senden: die **doppelte Bestätigung** aus S1 greift auch hier.
- Segment-Kostenstelle → passender **Clockodo-Service** (Mapping aus S2). Fehlt der Service in Clockodo, sauber melden (er wird regulär in S4 mit angelegt).
- **Idempotenz:** kein Doppel-Upload desselben Segments (lokale Sende-Markierung).

## Tests (Pflicht)
Wirft bei API-Fehler; kein app-weiter Key im Code/Repo; doppelte Bestätigung greift; Re-Upload erzeugt keine Duplikate; Audit-Eintrag pro Sendung.

## Hinweis
Sicherheitssensibel (Credentials). Bei Unklarheit über Key-Handling oder Rechte → Johannes fragen, nicht annehmen.
