# Rolling Handoff & Session Protocol

Status: verbindlich fuer alle Folge-Sessions dieser Branch-Arbeit.

## Ziel

Die Arbeit an WorkBasket, Dynamic Checkout, Datenobjekten, Bildkatalog, Moodboard Generator, Dokument-/Mailkatalog und Safety Engine muss rollierend, nachvollziehbar und nicht-destruktiv erfolgen.

Jede Session beginnt mit Wahrheit und endet mit Handoff. Keine Session darf stille Integrationsarbeit hinterlassen.

## Session-Start Pflicht

Im kanonischen Arbeitsordner ausfuehren:

```bash
pwd
git status
git branch --show-current
git branch -vv
git log --oneline --decorate -12
swift build
swift test
```

Wenn der Arbeitsbaum nicht sauber ist: stoppen, sichern, dokumentieren, entscheiden.

## Session Header

Jede Session-Datei beginnt mit:

```text
Datum:
Bearbeiter:
Pfad:
Branch:
HEAD:
Build:
Tests:
Scope dieser Session:
Externe Systeme beruehrt:
Writes durchgefuehrt:
Safety-Status:
```

## Session-Regel

Eine Session darf nur einen klaren Scope haben:

```text
S0 Wahrheit
S1 I/O Register
S2 Safety Engine
S3 DataObject Core
S4 WorkBasket Core
S5 CheckoutRun
S6 IntegrationHandshake
S7 Airtable Staging
S8 UI
S9 Preview
S10 sichere Outputs
S11 technische/kaufmaennische Handoffs
S12 Bildkatalog
S13 Moodboard Generator
S14 Dokument/Mail
S15 Gmail Draft
S16 Live-Gate
```

Keine Misch-Sessions mit Architektur, UI, Integrationswrites und Refactor gleichzeitig.

## Handoff am Ende

Jede Session endet mit:

```text
Was wurde gebaut:
Welche Dateien geaendert:
Welche I/O-IDs betroffen:
Welche Tests gelaufen:
Welche Safety-Tests gelaufen:
Welche externen Systeme gelesen:
Welche externen Systeme beschrieben:
Welche Writes wurden absichtlich NICHT gemacht:
Welche Risiken bleiben:
Naechster Schritt:
```

## Non destructive Branch Policy

Dieser Branch bleibt docs-first und safety-first. Code erst nach S0/S1/S2.

Regeln:

- Kein Merge in main ohne Review.
- Kein App-Code vor System Truth Map und I/O Register.
- Kein externer Write ohne registrierte I/O-ID.
- Kein Checkout ohne CheckoutRun.
- Kein Output ohne Preview.
- Kein Abschluss ohne Audit-Konzept.
- Kein Done ohne Live-Gate.

## Incident Handling

Wenn ein unklarer oder riskanter Write entdeckt wird:

```text
1. Aktion stoppen.
2. WriteIncident dokumentieren.
3. ReviewQueue-Eintrag erzeugen.
4. Session als unsafe markieren.
5. Weiterarbeit erst nach Entscheidung.
```

## Rollierende Artefakte

Folgende Dateien muessen wachsen, nicht ersetzt werden:

```text
docs/SYSTEM_TRUTH_MAP.md
docs/IO_REGISTER.md
docs/INTEGRATION_MATRIX.md
docs/WRITE_SAFETY_POLICY.md
docs/handoffs/workbasket_checkout_master_package/SESSION_LOG.md
```

Falls Dateien noch nicht existieren, in S0/S1 anlegen.
