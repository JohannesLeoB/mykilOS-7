# HANDOFF — Reversible TEST-Sandbox + Rechte-Matrix (mykilOS 8, Phase 1)

```
Stand:   2026-06-30 · Baseline 7.7.2 (d36063c) · Code-verifiziert.
Zweck:   Phase-1-Writes (neue Drive-Ordner, Airtable-Records, perspektivisch Clockodo/ClickUp) feuern
         AUSSCHLIESSLICH in klar markierte, REVERSIBLE Test-Bereiche, die nahtlos wieder löschbar sind.
Regel:   Produktivdaten bleiben unangetastet. DELETE NUR für TEST-markierte/TEST-eigene Daten. Sevdesk nie.
```

> **Status (mykilOS 8, Block A, 2026-06-30): Mechanik gebaut, zwei Stellen offen.**
> Gebaut + getestet: `ProvisioningModeStore` (§6, `.test`-Default, `.prod` hart gesperrt),
> `TestSandboxCleaner` (§3/§5, Doppel-Marker + eigene Lösch-Whitelist + Re-Fetch-Verifikation vor
> jedem Delete), `AirtableClient.deleteRecord` (einzige Stelle im Code, die überhaupt DELETE kann).
> **Offen:** (1) `AirtableClient.testDeletableMap` ist bewusst LEER — es gibt noch keine echte
> TEST-Tabelle, die Block D beim S4-Provisioning befüllt. (2) Der Drive-Teil von §3 (`_TEST_
> PROVISIONING`-Ordner) ist NICHT gebaut — `GoogleDriveClient` hat noch keine Delete-Fähigkeit, und
> es gibt vor Block D ohnehin keine Drive-TEST-Artefakte zu löschen. Details + Code:
> `Sources/MykilosServices/ProvisioningMode.swift`, `TestSandboxCleaner.swift`.

## 1. Aktuelle Rechte-Matrix (alle Integrationen außer Sevdesk)

| Integration | Lesen | Schreiben (heute im Code) | Scope/Gate |
|---|---|---|---|
| **Google Drive** | ✅ (`drive.readonly`, `drive.metadata.readonly`) | ✅ `uploadFile`, `createSubfolder` — **`drive.file`** | `drive.file` = App darf nur **selbst erstellte** Dateien/Ordner verwalten (inkl. löschen). Fremde/bestehende PROJEKTE-Ordner: **nicht** ohne `drive` (voll). |
| **Google Kalender** | ✅ (`calendar.events.readonly`) | ❌ (kein Write-Scope) | nur lesen / URL-Vorschlag |
| **Google Kontakte** | ✅ (`contacts.readonly`, `directory.readonly`) | ✅ `createContact` — **`contacts`** (voll) | gated über Karte→Bestätigung |
| **Gmail** | ✅ (`gmail.readonly`) | ✅ `createDraft` — **`gmail.compose`** (nur Entwurf, kein Versand) | gated |
| **Airtable** | ✅ `fetchRecords` (jede Base) | ✅ `createRecord`/`updateRecord` — **kein `deleteRecord`** | Whitelist `writableMap`; Inaktivierung nur per Status/Version |
| **Clockodo** | ✅ `ClockodoClient` (read) | ❌ kein POST im Code | read-only heute |
| **ClickUp** | ✅ (read) | ❌ kein Write im Code | read-only heute |
| **Lokal (GRDB)** | ✅ | ✅ voll CRUD (Notizen/Aufgaben/Audit/Chat) | lokal, unkritisch |

**Erkenntnis:** `drive.file` ist für eine **Test-Sandbox ideal** — die App kann eigene Ordner anlegen UND
löschen. Für Produktiv-Provisioning in **bestehende** PROJEKTE-Ordner bräuchte es später `drive` (voll) —
das ist eine **eigene Produktiv-Entscheidung**, nicht Teil von Phase 1.

## 2. ⚠️ Sicherheitsgrenze (verbindlich — auch wenn „alle Rechte" gewünscht sind)

„Erweiterte Schreibrechte einschalten" wird in der **sicheren** Lesart umgesetzt:
- **JA:** Writes für Phase 1 **aktiviert**, aber **ausschließlich in reversible TEST-Sandboxes** geroutet.
- **JA:** **DELETE erlaubt — aber NUR** für Daten, die die App selbst als TEST erzeugt hat (eigener Drive-Ordner,
  TEST-markierte Airtable-Records). Doppelt bestätigt, Audit-protokolliert.
- **NEIN (bleibt AUS bis ausdrückliche Produktiv-Freigabe):** Blanket-DELETE auf Produktiv-Airtable, voller
  `drive`-Scope auf fremde Ordner, jeglicher Sevdesk-Zugriff, Schreiben in Base `appkPzoEiI5eSMkNK` oder
  Drive `0AOeReQBQKkKBUk9PVA`. Diese Grenze ist nicht verhandelbar — sie schützt genau die Reversibilität,
  die du willst.

## 3. TEST-Sandbox je System (reversibel, klar markiert)

- **Drive:** ein dedizierter Ordner **`_TEST_PROVISIONING/`** (von der App erstellt → `drive.file` darf ihn
  voll verwalten + löschen). Dummy-Projektbäume (`JJJJ_Projektnr_Kunde_STR-Nr` + Unterordner) entstehen NUR
  darin. **Cleanup = den ganzen `_TEST_PROVISIONING`-Ordner löschen** → alles weg, ein Klick.
- **Airtable:** neue Test-Records bekommen einen **TEST-Marker** — Doppel-Strategie:
  (a) Name/Primärfeld-Präfix **`TEST_…`** UND (b) ein Feld **`Quelle = "TEST"`** (bzw. `Status = "TEST"`).
  Cleanup filtert **strikt** auf diesen Marker und löscht **nur** Treffer (kontrollierter, TEST-scoped DELETE).
  *Sauberste Variante (empfohlen): dedizierte TEST-Tabellen oder eine eigene Sandbox-Base, damit Cleanup
  „TEST-Tabelle leeren" ist und Produktivtabellen technisch gar nicht erreichbar sind.*
- **Clockodo / ClickUp:** in Phase 1 **kein** Write (heute read-only; echte Reversibilität dort schwierig).
  Falls doch nötig: nur gegen ein offensichtlich künstliches Test-Projekt, mit demselben Marker + Cleanup.

## 4. Bestätigungs-/Warn-Dialog (Pflicht vor jedem Sandbox-Write)
- Übersichts-Karte: **„TEST-MODUS — schreibt nach `_TEST_PROVISIONING` / TEST-markierte Records, reversibel."**
- **Risiko-Warnung**, wenn ein Ziel **nicht** als TEST erkennbar ist (würde Produktiv treffen) → **blockt** + warnt.
- Nomenklatur-Warnung (aus [[HANDOFF_MYKILOS8_KICKOFF]] §9): bricht ein Ordnername das Schema (fehlende
  STR-Nr ohne ORT-Fallback) → Warnung statt Anlage, auch im Test.
- Zweistufig bei DELETE (Cleanup): Übersicht „N Test-Ordner + M Test-Records werden gelöscht" → zweiter „Ja".

## 5. Cleanup („nahtlos sauber löschen")
Ein `TestSandboxCleaner` (neu, mykilOS 8): listet alle TEST-Artefakte (Drive `_TEST_PROVISIONING`-Inhalt +
Airtable-Records mit TEST-Marker), zeigt sie in einer Karte, löscht nach Doppelbestätigung, schreibt Audit-
Einträge. Idempotent (mehrfach ausführbar). **Findet nur TEST-Markiertes — kann Produktives technisch nicht treffen.**

## 6. TEST/PROD-Schalter
Ein Setting `provisioningMode = .test | .prod` (Default `.test`). Dieselbe Provisioning-Logik (S4) läuft gegen
Sandbox oder Produktiv. `.prod` ist **gesperrt**, bis (a) die Nomenklatur bestätigt ist, (b) die Lern-Runde aus
dem Bestand gelaufen ist, (c) Johannes die Produktiv-Scopes (`drive` voll, ggf. Airtable-DELETE-Policy) explizit
freigibt. So fließt nie versehentlich Echtbetrieb.

## 7. Write-Backup-Base (Sicherheitskopie ALLER Schreibvorgänge — append-only, KEIN DELETE)

> **Status (Block A, aktualisiert 2026-06-30): Base von Johannes live angelegt.** „mykilOS 8
> Backup Base" (`app56DTbSoqPvZhom`, Tabelle vermutlich `Write-Shadow-Log`, Table-ID
> `tblYQVdeHP2Zvgt8m`) ist verdrahtet — `AppState.writeShadow` zeigt jetzt auf diese Base,
> `AirtableClient.writableMap` erlaubt CREATE in `app56DTbSoqPvZhom: ["Write-Shadow-Log"]`.
> **Unverifiziert:** der für diese Session verfügbare Airtable-MCP konnte das Schema NICHT
> gegenprüfen (403 — sieht nur Mastermind). Stimmt der Tabellenname/die Feldnamen nicht exakt
> (`Zeitstempel`/`Nutzer`/`Aktion`/`Ziel-System`/`Ziel-Base`/`Ziel-Tabelle`/`Ziel-Record-ID`/
> `Payload-JSON`/`Vorwert-JSON`/`TEST-PROD`/`Ergebnis`), scheitert NUR der externe Spiegel
> (non-fatal, jetzt sichtbar geloggt unter `WRITE_SHADOW_BACKUP_FEHLT` mit Fehlertext) — der
> lokale GRDB-Eintrag (die eigentliche Sicherheitskopie) passiert immer. **Nächster Schritt:**
> Johannes verifiziert live (echten Write auslösen, z. B. Intake-Submit, dann in der Backup-Base
> nachschauen, ob der Record ankommt).

**Jeder Schreibvorgang in die Datenkerne** (Airtable CREATE/PATCH, Drive-Ordner/Datei-Anlage, künftig
Clockodo/ClickUp-Writes) wird **zusätzlich als Sicherheitskopie** in eine **separate Backup-Base** geschrieben —
**append-only, ohne jegliche Löschrechte**. So ist jeder Write rekonstruierbar/rücklesbar, auch wenn das Ziel
später geändert oder (im TEST-Fall) gelöscht wird.

- **Heimat:** eigene Airtable-Base **`mykilOS-Backup`** (getrennt von Mastermind + Artikel-Base), **NICHT** auf
  einer DELETE-Whitelist, NIE PATCH/Overwrite — nur `createRecord`. (Live mit Johannes anlegen.)
- **Pro Write ein Backup-Record (Write-Shadow):** Zeitstempel · Nutzer · Aktion (create/update) · Ziel-System
  (Airtable/Drive/Clockodo/ClickUp) · Ziel-Base+Tabelle bzw. Drive-Ordner · Ziel-Record-/File-ID · **vollständiges
  Payload-JSON** (was geschrieben wurde) · vorheriger Wert bei Update (Rückrollbarkeit) · TEST/PROD-Flag · Ergebnis (ok/fehler).
- **Mechanik:** ein `WriteShadowRecorder`, durch den **alle** App-Writes laufen (`AirtableClient.createRecord/
  updateRecord`, `GoogleDriveClient.uploadFile/createSubfolder`, …). Auch **fehlgeschlagene** Versuche werden
  protokolliert (Reihenfolge Ziel↔Backup live festlegen).
- **Verhältnis zu Bestehendem:** ergänzt — ersetzt nicht — den lokalen `AuditStore` (GRDB) + das Airtable
  `Datenstrom-Log`. Audit = „was hat der Nutzer bestätigt", Datenstrom-Log = „Sync-Handshake",
  **Backup-Base = vollständige Wiederherstellungskopie der Payloads**.
- **Eiserne Grenze:** Die Backup-Base hat **keine** Lösch-/Überschreibrechte — der unantastbare Schreib-Spiegel.
  Auch der `TestSandboxCleaner` (§5) löscht NUR die TEST-Artefakte im **Ziel**, **nie** die Backup-Records.

## 8. Tests (Pflicht)
Sandbox-Write erzeugt nur TEST-markierte Artefakte · Cleanup entfernt ausschließlich TEST-Markiertes (Produktiv-
Fixture bleibt unberührt) · Warn-Dialog blockt bei Nicht-TEST-Ziel · Nomenklatur-Warnung bei Schema-Bruch ·
Cleanup ist idempotent · **jeder Write erzeugt genau einen Backup-Record (Payload identisch), Backup-Base akzeptiert
kein DELETE/PATCH**.

> Diese Sandbox ist die **erste Bau-Einheit** vor jedem realen Provisioning. Erst wenn sie reversibel + getestet
> steht, wird über den TEST/PROD-Schalter an echte Daten gedacht.
