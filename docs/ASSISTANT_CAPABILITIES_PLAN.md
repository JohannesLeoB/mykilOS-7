# Assistent-Fähigkeiten — Ausbauplan

**Ausgangswunsch (User, 2026-06-27):** Der Assistent soll Mails, Kalender und
Projekte komplett durchsuchen können, alle Daten crawlen, alle Projektordner
und Unterordner kennen, Mails kennen/entwerfen/verwerfen, Termine in Projekte
schreiben, Notizen verwalten, Stundeneinträge in Clockodo vorbereiten,
Kundenmails zusammenfassen, Kontakte suchen, Bilder suchen, Angebote suchen.

Das ist ein großer, vielteiliger Ausbau — keine einzelne Aufgabe. Dieser Plan
zerlegt ihn in Einzelstücke, zeigt was schon existiert vs. was neu gebaut
werden muss, und sortiert nach **harter Architekturregel**: *"Signale sind
Vorschläge. Schreiben nur über Action-Card → Bestätigung → Audit."* — das
gilt für **jeden** Schreib-Punkt unten, ausnahmslos.

---

## Aktueller Stand (Code-Realität, nicht Annahme)

`AssistantToolRegistry` (`Sources/MykilosServices/AssistantTool.swift`) hat
aktuell genau **3 Tools**, alle read-only oder reine Vorschläge:

| Tool | Was es tut |
|---|---|
| `SearchGmailTool` | Gmail-Suche, read-only |
| `ListCalendarTool` | Kalender-Termine listen, read-only |
| `SuggestCalendarEventTool` | Schlägt einen Termin vor → `CalendarActionCard` öffnet Google Calendar im Browser zum manuellen Anlegen. **Kein API-Write.** |

Alles andere aus dem Wunsch (Drive-Crawling, Mail-Drafts, echtes
Kalender-Schreiben, Notizen-Verwaltung durch den Assistenten, Clockodo-Vorbereitung,
Kontakt-/Bild-/Angebots-Suche als Tool) **existiert als Assistent-Tool noch
nicht** — auch wenn die zugrundeliegenden Clients (GoogleDriveClient,
GoogleContactsClient, ClockodoClient, NoteStore) teilweise schon da sind und
in eigenen Widgets genutzt werden, nur nicht vom Assistenten aufrufbar.

---

## Zerlegung in Einzelstücke

### A. Lesend/Suchend (kein neues Schreibrisiko — einfacher zu bauen)

| # | Wunsch | Bauklotz | Aufwand |
|---|---|---|---|
| A1 | Mails komplett durchsuchen | `SearchGmailTool` existiert — ggf. Scope/Query erweitern | klein |
| A2 | Kalender durchsuchen | `ListCalendarTool` existiert | klein (evtl. schon ausreichend) |
| A3 | Alle Projektordner + Unterordner kennen | Neues `SearchDriveTool`, nutzt bestehenden `GoogleDriveClient.listFolder` rekursiv über `project.links.driveFolderID` | mittel — rekursives Crawlen über 31 Projektordner ist nicht trivial schnell, braucht Tiefenlimit + Cache |
| A4 | Kontakte suchen | Neues `SearchContactsTool`, nutzt bestehenden `GoogleContactsClient` (schon in ContactsWidget genutzt) | klein |
| A5 | Bilder suchen | Neues `SearchImagesTool` — Filter auf `mimeType` beginnt mit `image/` innerhalb von A3's Crawl-Ergebnis | klein, baut auf A3 auf |
| A6 | Angebote suchen | Neues `SearchOffersTool` — nutzt dieselbe Logik wie `OffersTabView`/`DriveOfferWatcher.detectOffers`, projektübergreifend statt nur 1 Projekt | klein, Logik existiert schon |
| A7 | Kundenmails zusammenfassen | Baut auf A1 auf + Claude-Zusammenfassung (Pattern existiert schon im Assistenten für Insights) | klein, wenn A1 steht |

### B. Schreibend — MUSS durch Action-Card → Bestätigung → Audit

| # | Wunsch | Bauklotz | Aufwand | Schreibziel |
|---|---|---|---|---|
| B1 | Mails entwerfen | Neues `DraftEmailTool` + `EmailDraftActionCard` (Vorschau, kein Senden ohne Klick) | mittel — braucht Gmail-API-Write-Scope, aktuell nur read-only verbunden | Gmail-Entwurf |
| B2 | Mails verwerfen | Teil von B1 (Entwurf löschen statt senden) | klein, wenn B1 steht | Gmail-Entwurf löschen |
| B3 | Termine in Projekte schreiben | **Unterschied zu `SuggestCalendarEventTool`:** das öffnet nur den Browser. Echtes Schreiben braucht Calendar-API-Write-Scope + `CalendarActionCard`-Bestätigung, die tatsächlich `events.insert` aufruft, nicht nur eine URL öffnet | mittel — Google-Verbindung aktuell nur Lesescope, Scope-Erweiterung + Re-Consent nötig |
| B4 | Notizen verwalten (Assistent) | Neues `WriteNoteTool` → bestehender `NoteStore.save()` (existiert schon, GRDB-backed), aber Aufruf muss über Bestätigung laufen, nicht direkt vom Tool-Loop | klein-mittel |
| B5 | Stundeneinträge in Clockodo **vorbereiten** | Wichtig: "vorbereiten" ≠ "buchen". `ClockodoClient` ist aktuell rein lesend (`todaysEntries()`). Vorschlag: Tool erzeugt einen **Entwurf** (Projekt, Dauer, Text), zeigt ihn als Action-Card — der User bucht selbst final in Clockodo, mykilOS schreibt nie direkt in Clockodo (kein Clockodo-Write-Client existiert, bewusst nicht bauen ohne explizite Freigabe) | mittel, aber **mit eingebauter Grenze**: Vorschlag ja, Buchung nein |

---

## Empfohlene Reihenfolge

1. **A3 zuerst** (Drive-Crawling) — das ist die Grundlage, auf der A5 und Teile
   von A6 aufbauen, und der Wunsch "alle Projektordner/Unterordner kennen"
   ist explizit Punkt 1 in der Anfrage.
2. **A1, A2, A4, A6** parallel möglich — alle klein, alle read-only, alle
   nutzen bestehende Clients.
3. **A7** nach A1.
4. **B4 (Notizen)** — kleinster Schreib-Baustein, gutes erstes Beispiel für
   "Assistent schreibt über Bestätigung", bevor die größeren B-Punkte angegangen werden.
5. **B3 (echtes Kalender-Schreiben)** und **B1/B2 (Mail-Entwürfe)** brauchen
   beide eine **Google-Scope-Erweiterung** (aktuell nur
   `GoogleOAuthScope.readOnlyDefaults`) — das heißt: bestehende Verbindungen
   müssen neu autorisiert werden (Re-Consent-Dialog). Das ist ein
   User-sichtbarer Schritt, sollte nicht überraschend passieren — vorher
   ankündigen.
6. **B5 (Clockodo-Vorbereitung)** zuletzt — am meisten Neuland (keine
   bestehende Action-Card-Vorlage für "Vorschlag, der nirgends automatisch
   gebucht wird"), und bewusst **ohne** echten Clockodo-Write-Client, um
   die Grenze "vorbereiten, nicht buchen" nicht versehentlich zu verwischen.

---

## Offene Entscheidungen, bevor B-Punkte gebaut werden

- **Google-Scope-Erweiterung (B1/B3):** Damit ändert sich das, was die App
  beim Verbinden anfragt (von rein lesend zu teilweise schreibend für Mail-
  Entwürfe/Kalender). Das ist eine Vertrauens-/Berechtigungs-Entscheidung,
  die der User bewusst treffen sollte, nicht ich allein im Code.
- **B5-Grenze:** Bitte bestätigen, dass "vorbereiten" wirklich heißt "Vorschlag
  zeigen, User bucht selbst in Clockodo" und nicht doch "mykilOS soll
  irgendwann selbst in Clockodo schreiben" — das wäre ein neuer NO-GO-naher
  Bereich (echtes Schreiben in ein Abrechnungssystem) und sollte explizit
  und einzeln entschieden werden, nicht im selben Atemzug wie der Rest.

---

## Status

| Punkt | Status |
|---|---|
| A1–A7 (lesend) | ⬜ offen |
| B1–B5 (schreibend) | ⬜ offen, blockiert teilweise auf Scope-Entscheidung |

Diese Tabelle bei Fortschritt aktualisieren — wie `IDEEN_UND_BACKLOG.md`.
