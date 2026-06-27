# Ideen & Backlog

Lebendes Dokument, **kein Changelog** (das übernimmt CLAUDE.md's Status-
Tabelle für Erledigtes). Hier landet alles, was angedacht, aber noch nicht
entschieden, geplant oder umgesetzt ist — unabhängig davon, in welcher
Session die Idee entstanden ist. Wird bei jeder Session zuerst gelesen und
am Ende aktualisiert, damit nichts in einzelnen Handoffs verloren geht.

**Format:** Jeder Eintrag hat Status, Quelle (wann/wodurch entstanden) und
Verknüpfung zu Handoffs/Code, falls vorhanden. Status-Werte:
- 💡 **Idee** — nur angedacht, noch nicht bewertet/entschieden
- 📋 **Geplant** — Entscheidung gefallen, noch nicht umgesetzt
- 🚧 **Begonnen** — teilweise umgesetzt
- ✅ **Erledigt** — umgesetzt, bleibt hier als Historie mit Verweis stehen
- ❌ **Verworfen** — bewusst nicht weiterverfolgt, mit Begründung

---

## Assistent-Ausbau (großer Block, eigenes Dokument)

### 📋 Vollständiger Such-/Schreib-Ausbau des Assistenten
**Quelle:** User-Wunsch 2026-06-27. Mail/Kalender/Drive komplett durchsuchen,
Projektordner+Unterordner crawlen, Mail-Entwürfe, echtes Kalender-Schreiben,
Notizen-Verwaltung, Clockodo-Vorbereitung, Kontakt-/Bild-/Angebots-Suche.
Vollständig zerlegt in [ASSISTANT_CAPABILITIES_PLAN.md](ASSISTANT_CAPABILITIES_PLAN.md)
(7 Lese-Punkte, 5 Schreib-Punkte, Reihenfolge-Empfehlung, zwei offene
Entscheidungen: Google-Scope-Erweiterung für Mail/Kalender-Write, und ob
Clockodo wirklich nur "vorbereiten" bleibt statt selbst zu buchen).

---

## Architektur & Datenfluss

### 📋 ClickUp als Quelle für `ProjectKind`
**Quelle:** Live-Wiring-Session 1 (2026-06-27). Drive-Ordnernamen lassen
`ProjectKind` (kitchen/lighting/addendum/lead/quote) nicht erkennen.
**Plan:** Handle/Link-Konnektor (ClickUp-Listen-ID pro Projekt, Feld
`ClickUp-Liste` existiert bereits in `Project.links` und in der Airtable-
Tabelle `Projekte`) + eine Übersetzungsregistry, die ClickUp-Daten auf
`ProjectKind` mapped. Der neue ClickUp-Sandbox-Space "MYKILOS API
TESTSPACE" (`90128024109`) ist der vorgesehene Testort dafür.
**Noch offen:** genaues Mapping-Schema (welches ClickUp-Feld/Status/Tag
→ welcher `ProjectKind`) ist nicht entschieden.

### 📋 Archiv-Übersetzungsregistry für `_PROJEKTE_ARCHIV`
**Quelle:** Live-Wiring-Session 1. ~200+ archivierte Projektordner
(2018–2026) mit komplett anderem, uneinheitlichem Namensschema
(Standort-Präfixe `B_`/`HH_`/`K_`/`WI_` statt `JJJJ_lfdNr_Kunde`), mehrfach
verschachtelte Jahres-Unterordner.
**Plan:** eigener Namens-Mapping-Parser fürs alte Schema + Airtable-Tabelle
`Archiv-Übersetzung` (Schema bereits angelegt: Alter Ordnername, Vermutete
Projektnummer, Jahr, Standort-Präfix, Status — aktuell leer, 0 Records).
**Bewusst zurückgestellt**, kein Termin.

### 💡 "Drive-Ordner anlegen"-Automatisierung über ClickUp
**Quelle:** Beim Connector-Recheck dieser Session im ClickUp-Sandbox
entdeckt — die Test-Liste "KUE-2026-014 Küche Müller TEST" hat bereits ein
Custom Field `Drive-Ordner anlegen` (Checkbox) angelegt.
**Noch offen:** Was genau soll dieser Trigger tun? (Vermutung: neuer
ClickUp-Task mit Checkbox aktiviert → Drive-Ordner für neues Projekt
automatisch anlegen, inkl. Unterordner-Struktur `00 INFOS`/`02 CAD`/
`03 PRÄSENTATION`/`04`/`05`.) Mit dem User klären, bevor das gebaut wird —
das wäre der erste echte **Schreibzugriff** auf Drive (aktuell strikt
read-only laut NO-GO).

### 💡 Drei-Kopien-Redundanzmodell — vierte Frage: was wenn Airtable wechselt?
**Quelle:** User-Kommentar dieser Session: *"Wir brauchen Redundanz [...]
Airtable bleibt evtl. nicht der permanente Hub, ein anderes Tool könnte es
später ersetzen."* Umgesetzt: 3 Kopien (Airtable/lokaler Cache/Git-JSON,
siehe `docs/registry/README.md`).
**Noch offen / Idee:** Falls Airtable tatsächlich ersetzt wird — welches
Tool käme infrage, und müsste die App (`AirtableClient`/`AirtableRegistry`)
dann durch eine generische Sync-Schnittstelle ersetzt werden, damit nicht
wieder hartkodierter Airtable-Code überall verteilt ist? Reine Idee, keine
Entscheidung.

---

## Neue Tabs / Oberflächen

### 📋 Zeichnungen-Tab mit PDF-Vorschau
**Quelle:** User-Entscheidung in dieser Session. Neuer Projekt-Tab, Quelle
`02 CAD`-Unterordner. Technisch unklarster Punkt: PDF-Vorschau in SwiftUI
(QuickLook/PDFKit), vermutlich echter Datei-Download nötig (aktuell wird
bei Drive nur `webViewLink` im Browser geöffnet, kein Download/Cache).
Details: [HANDOFF_LIVE_WIRING_1.md](handoffs/HANDOFF_LIVE_WIRING_1.md)
Abschnitt 5a, Schritt D.

### 📋 Material-Tab
**Quelle:** User-Entscheidung. Quelle `03 PRÄSENTATION`-Unterordner,
vermutlich einfache Dateiliste wie Angebote-Tab, kein PDF-Vorschau-Bedarf.

### 💡 Abnahme-Bereich für Abnahmeprotokoll
**Quelle:** User-Wunsch, am wenigsten konkret. Noch keine Drive-Quelle
zugeordnet — ungeklärt, ob eigener Unterordner oder eigenes Datenmodell
(strukturiertes Formular statt Dateiliste). **Mit dem User klären, bevor
Umsetzung beginnt.**

### 💡 Timeline-Tab — Calendar jetzt, ClickUp später
**Quelle:** User-Entscheidung in dieser Session. Aktuell `ComingTabView`-
Platzhalter. Phase 1: Google Calendar (bestehender `GoogleCalendarClient`,
`calendarQuery`). Phase 2 (nicht terminiert): ClickUp-Aufgaben mit
Fälligkeitsdatum einblenden, sobald Aufgabe "ClickUp-Handle für
ProjectKind" (oben) steht und die Datenqualität dafür ausreicht.

---

## Bugs (real, kein Feature-Wunsch)

### 📋 Hartkodierte Demo-Werte in drei Widgets
**Quelle:** Code-Audit in Live-Wiring-Session 1.
- `ProjectHeroView.swift` — Budget-Balken fix auf 72 % für jedes Projekt.
- `FocusWidget.swift` — Text ignoriert das echte `projectID` des Signals.
- `CashWidget.swift` — Angebotstext hartkodiert, "In Review übernehmen"
  persistiert nichts (nur `@State`, kein Audit-Eintrag).

Details mit exakten Zeilennummern:
[HANDOFF_LIVE_WIRING_1.md](handoffs/HANDOFF_LIVE_WIRING_1.md) Abschnitt 5a,
Schritt B.

### 📋 Demo-Signal-Buttons emittieren Fake-Signale statt echten Poll
**Quelle:** Code-Audit. `SignalDemoView.swift` + `TodayView.swift` (Zeile
144–146, feste Projekt-ID `"ME-24"` — bricht, sobald DemoSeed ersetzt
wird). Soll `DriveOfferWatcher.poll(...)` für das echte Projekt sofort
auslösen statt ein Fake-Signal zu emittieren.

---

## Bekannte offene technische Fragen (nicht terminiert)

### 💡 Google "Desktop App"-OAuth — `client_secret` nötig?
**Quelle:** Seit Akt 3, Schritt 1 offen. Ob Googles "Desktop App"-Client-
Typ bei PKCE zusätzlich ein `client_secret` verlangt, ist nie live
getestet worden (V5 unterstützte es optional). Falls beim ersten echten
Verbinden `invalid_client` auftritt: `clientSecret`-Parameter in
`GoogleOAuthPKCEService` nachziehen.

### 💡 "Nie verbunden" vs. "Sitzung abgelaufen" bei Google-Refresh
**Quelle:** Seit Schritt 3 offen, bewusst für V1 zusammengefasst (beide
zeigen `.permissionRequired`). Ein eigener `.authExpired`-State wäre für
V1 Over-Engineering — als Idee hier vermerkt, falls es in der Praxis doch
zu Verwirrung führt.

### 💡 Airtable-MCP-Connector ohne Record-Write
**Quelle:** Live-Wiring-Session 1 — `create_records_for_table` existiert im
aktuellen Connector-Toolset nicht (nur Schema-Tools). Workaround per
Personal-Access-Token + lokalem `curl`-Skript funktioniert, ist aber kein
dauerhaft eingebauter App-Mechanismus. Falls der Connector das später
nachrüstet: Workaround obsolet, aber unkritisch.

---

## Hinweis für zukünftige Sessions

Dieses Dokument ist **additiv** — neue Ideen unten/in der passenden
Sektion ergänzen, Status bei Fortschritt ändern, nichts löschen (außer bei
❌ Verworfen kurz die Begründung ergänzen und stehen lassen, das ist auch
eine Information). Wenn ein Punkt in einem Handoff im Detail beschrieben
ist, hier nur kurz zusammenfassen + verlinken, nicht duplizieren.
