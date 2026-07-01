# Ideen & Backlog

Lebendes Dokument, **kein Changelog** (das übernimmt CLAUDE.md's Status-
Tabelle für Erledigtes). Hier landet alles, was angedacht, aber noch nicht
entschieden, geplant oder umgesetzt ist — unabhängig davon, in welcher
Session die Idee entstanden ist. Wird bei jeder Session zuerst gelesen und
am Ende aktualisiert, damit nichts in einzelnen Handoffs verloren geht.

> **⚠️ MUTED — Hinweis für alle Sessions:**
> Dieses Dokument ist standardmäßig stumm. Lesen ist erlaubt, aber keine Session
> darf Einträge hieraus aufgreifen, priorisieren oder umsetzen — außer Johannes
> verweist explizit darauf ("schau ins IdeenLog", "Punkt X aus dem Backlog").
> Dieses Dokument wächst kontinuierlich durch verschiedene Sessions und
> Koordinations-Runden. Mehr Einträge als erwartet = normal, kein Handlungsbedarf.

**Format:** Jeder Eintrag hat Status, Quelle (wann/wodurch entstanden) und
Verknüpfung zu Handoffs/Code, falls vorhanden. Status-Werte:
- 💡 **Idee** — nur angedacht, noch nicht bewertet/entschieden
- 📋 **Geplant** — Entscheidung gefallen, noch nicht umgesetzt
- 🚧 **Begonnen** — teilweise umgesetzt
- ✅ **Erledigt** — umgesetzt, bleibt hier als Historie mit Verweis stehen
- ❌ **Verworfen** — bewusst nicht weiterverfolgt, mit Begründung

---

## Architektur-Vorschlag: WorkBasket/Checkout-Pipeline (generisches Schreib-Modell)

### 📋 Generische DataObject→WorkBasket→CheckoutRun→Preview→Review→Audit-Pipeline
**Quelle:** Branch `handoff/workbasket-checkout-architecture-2026-07-01` (vermutlich
Codex-Session, 2026-07-01), gelesen + eingeordnet während der mykilOS-8.0-Konsolidierung.
**Status:** S0/S1 (reine Doku, 0 Code) laut eigener Stop-Regel abgeschlossen — kein
Feature-Code, bevor Johannes den I/O-Stand akzeptiert hat.

**Kernidee:** Statt jedes Schreib-Feature (Warenkorb, Angebote, CAD-Handoff, Mail,
Moodboards …) einzeln zu bauen, alle über dieselbe Pipeline: `DataObject →
WorkBasketItem → WorkBasket → CheckoutRun → Preview → Review/Safety → Output →
Audit → Postflight`. 18 durchgeplante I/O-Einträge (IO-001–IO-018), alle ❌ noch
nicht gebaut — u. a. Schätzung/Vergleich/Angebots-Template/Projektanlage-Staging
(überschneidet sich mit Block-F-Umfang), CAD-Handoff, Bildindex, Moodboard-Generator,
Firefly-Prompts, Dokument-/Mail-Vorlagen, Gmail-Drafts, Protokollpakete,
Auftragsbestätigungen (alles NEU, nicht im Rolling Plan).

**Bemerkenswert:** Zitiert unabhängig dieselbe HTTP-422-Lehre (Number-Feld als String,
Linked-Record mit rohem String) wie unsere eigene Live-Untersuchung vom selben Tag,
und nennt `ProjektProvisioningService` (mykilOS-8 Block D) explizit als Vorbild für
die künftige `CheckoutRun`-Implementierung.

**Wichtige Einschränkung:** Diese Branch ist von `main`/v7.7.2 abgeleitet, NICHT von
den mykilOS-8-Feature-Branches (Block A–D) — kennt `ExternalMappingRegistry`,
`WriteShadowRecorder`, `ProvisioningLedger` nicht im eigenen Code. Eigene Risiko-Notiz:
"Vor S3+ (echter Code) mit Johannes klären, welcher Branch der Merge-Zielpunkt ist."

**Offene Grundsatzentscheidung (nicht Teil der aktuellen Konsolidierung, für 8.1
mitzunehmen):** Rolling-Plan-Blöcke E/F/G wie geplant als Einzelfeatures weiterbauen,
oder auf dieses generische Pipeline-Modell umschwenken/verschmelzen? Branch bleibt bis
dahin unangetastet liegen.

---

## 🚨 P0-BLOCKER — Projektübersicht überlagert und blockiert die Sidebar

### 🟡 FIX COMMITTED (9ddf75a) — Live-Abnahme durch Johannes weiterhin ausstehend
**Quelle:** Live-Screenshots von Johannes, 2026-06-28 um 09:38/09:39;
forensische Auswertung durch Codex. **Korrigiert 2026-07-01** (Doku-Konsolidierung):
dieser Eintrag hieß bisher fälschlich "🚨 OFFEN", obwohl CLAUDE.md bereits seit
2026-06-28 "FIX COMMITTED · Live-Abnahme ausstehend" dokumentiert — reine
Doku-Inkonsistenz zwischen den beiden Dateien, kein neuer Code-Fund. Der Fix selbst
(`ZStack(.bottom)` → `.bottomLeading`, `VStack.leading`, Tab-Bar `maxWidth: .infinity,
alignment: .leading`) ist committed; **die Live-Abnahme am echten Gerät (Sidebar bei
aktiver Übersicht vor/während/nach Widget-Ladevorgängen klickbar) steht weiterhin aus**
— siehe Phase 4 der aktuellen Konsolidierungs-Session.
**Priorität:** P0 — vor S18/S20-Feature-Arbeit beheben und live abnehmen.
**Handoff:** [HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md](handoffs/HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md)

**Reproduktion:**
1. Projekt öffnen.
2. „Angebote“, „Timeline“ oder „Material“ aktivieren: Sidebar funktioniert.
3. „Übersicht“ aktivieren: Hero-/Tab-Inhalte werden links abgeschnitten; Sidebar
   bleibt sichtbar, nimmt aber keine Klicks mehr an.

**Kein Sidebar-Toggle:** Die Sidebar wird nicht absichtlich ausgeblendet. Das
Overview-Widget-Board wird horizontal übergroß; seine unsichtbare
Interaktionsfläche überlagert die Sidebar. Der Fehler ist deshalb gleichzeitig
Layout-, Navigation- und Accessibility-Blocker.

**Root Cause:** `ProjectWidgetBoardView` verwendet als einziger Tab ein
intrinsisch vermessenes SwiftUI-`Grid` mit flexiblen/asynchron wechselnden
Widgets und einem `Color.clear`-Filler. `.clipped()` versteckt Überstand nur
optisch und löst das Hit-Testing nicht.

**Nicht als Fix akzeptieren:**
- nur `.clipped()`, `.fixedSize`, `.layoutPriority` oder `WindowGuard`
- nur Build-/Unit-Test-Erfolg
- Prüfung ausschließlich in anderen Projekttabs

**Definition of Done:**
- Übersicht, Hero und alle Tabs bleiben vollständig innerhalb des rechten Panes.
- Sidebar bleibt vor, während und nach allen Widget-Ladevorgängen anklickbar.
- Prüfung unmittelbar und nach 300/800/1800 ms.
- Mehrere Projekte und Fenstergrößen live geprüft.
- Ergebnis mit Screenshots im Ereignisprotokoll/Handoff dokumentiert.

---

## Assistent als Kontakt- und Beziehungsintelligenz

### 💡 Assistent kennt alle Kontakt-Zusammenhänge (Vollbild-Vision)
**Quelle:** User-Wunsch 2026-06-27 (Kontakte-Import-Session).
**Vision:** Der Assistent hat ein vollständiges, lebendiges Bild aller
Personen, die mit MYKILOS in Berührung kommen — projektbezogen, aus
Google Kontakten und aus dem gesamten Mail-Verlauf. Er kennt:
- Wer ist Projektkunde, Architekt/Planer, Lieferant, Handwerker, Team?
- Welche Person gehört zu welchem Projekt (auch wenn der Name nur in einer
  Mail-CC oder im Betreff steht)?
- Wer hat wen vermittelt (z. B. Christian Westphal → Dr. Klose)?
- Welche Firmen/Domains tauchen project-übergreifend auf (Weichsel78,
  MGB Naturstein, HS-Architekten arbeiten an mehreren Projekten)?
- Welche Kontakte fehlen noch (25 von 31 Projekten ohne direkten
  Kundenkontakt in den CSV-Exporten)?

**Aktueller Stand (2026-06-27):**
- Airtable Mastermind hat jetzt eine **Kontakte-Tabelle** mit 914 Einträgen
  (891 aus CSV-Export + 23 aus Gmail-Recherche).
- 6 Projekte haben direkte Projektkunden-Links; 25 Projekte sind noch offen
  (Bellavance, Cirnavuk, Hustadt etc. haben Kunden per Gmail gefunden und
  bereits in Airtable eingetragen, aber noch nicht alle 31 abgedeckt).
- Gmail-Recherche liefert deutlich mehr Kontext als CSV-Export allein:
  Projektnummern im Betreff (#Cirnavuk, #Schmid), CCs mit Kunden-Mails,
  Architekten-Kontakte als Vermittler.

**Nächste Schritte für die App-Umsetzung:**
- AssistantWidget: Kontakte-Kontext aus Airtable laden (pro Projekt: wer
  ist der Ansprechpartner, wer ist der Architekt, wer sind die Lieferanten?)
- Gmail-Suche nach Projektnamen als Assistenz-Funktion (bereits im
  ASSISTANT_CAPABILITIES_PLAN.md als Lese-Punkt A3/A4 vorgesehen)
- Kontakte-Tabelle als lebendes Gedächtnis: neue Mail-Kontakte automatisch
  vorschlagen (Assistent erkennt unbekannte Absender in Projekt-Threads)
- Beziehungsgraph: wer arbeitet mit wem zusammen? (z. B. HS-Architekten
  orchestriert mehrere Gewerke bei Projekten 2026-021 und 2026-026;
  Weichsel78 ist Tischler für 6+ Projekte)

**Daten-Qualitätslücken:**
- 371 Kontakte haben keine E-Mail (nur Name/Telefon aus CSV-Export)
- Manche Projekt-Kunden sind nur per Firmen-Mail erreichbar (z. B. Wartenb
  erg Vermögensverwaltung), kein privater Kanal
- May, Wobig, von Boch, Loidl, Mohadjer, Cirnavuk (Kunde direkt),
  Zitscher (Kunde direkt) — Kunden-E-Mails noch unbekannt

---

## Clockodo Zuhörer — Smart Time Logger

### 📋 Clockodo Zeitbuchung aus Assistent-Chat + Kalender/Mail-Vorschlägen
**Quelle:** User-Wunsch 2026-06-28. Architektur definiert, Airtable-Schema live,
Code-Implementierung steht noch aus (nächste Session).

**Kernregel — User-Scoping:**
Jeder angemeldete User bucht, sieht und editiert **ausschließlich seine eigenen**
Zeiteinträge. `ClockodoDraftEntry` hat `clockodoUserID: Int`, alle GRDB-Queries
filtern darauf. Clockodo-API-Credentials (E-Mail + API-Key) liegen per User im
Keychain — wer die Creds nicht hat, kann nicht buchen. Clockodo erzwingt dies
auch serverseitig (POST als eigener User-Account).

**Airtable-Schema (live in `appuVMh3KDfKw4OoQ` seit 2026-06-28):**
- `Clockodo-Nutzer` (`tblPbly2br8mR2kaU`) — 4 Records mit Feld
  `Airtable-Entwurf-Tabelle` (`fldsoeQHWDmbBt7FM`) → zeigt auf persönl. EW-Tabelle.
- `Clockodo-EW-Johannes` (`tbl4vZ2UFyeTRD8hd`) — persönliche Arbeitstabelle.
- `Clockodo-EW-Jilliana` (`tblXQIDrvPVN9ijI9`) — persönliche Arbeitstabelle.
- `Clockodo-EW-Daniel`   (`tblNDVve3jjJ9s8HB`) — persönliche Arbeitstabelle.
- `Clockodo-EW-Frauke`   (`tblRrqIQZmm2DosJT`) — persönliche Arbeitstabelle.
  Felder je EW-Tabelle: Datum, Von, Bis, Dauer-h, Projekt, Kunden-ID,
  Leistung, Leistungs-ID, Notiz, Billable, KW, Quelle, Status.
- `Clockodo-Buchungen` (`tblYQxlauwej7FD1w`) — Master-Audit-Log nach Bestätigung.
- `Clockodo-Leistungen` (`tblRtsegocdpM8CJd`) — bereits befüllt (8 Services).
- `Kunden.Clockodo-Kunden-ID` — gemappt für 10 von 30 Kunden.

**6-Schichten-Architektur (Code pending):**
1. **Intent Layer**: `ClaudeConversationEngine` neuer Intent `clockodoDraft`,
   extrahiert Dauer + Leistungstyp + Kunden-/Projektreferenz aus Freitext.
2. **Resolution Layer**: `ClockodoDraftResolver` → Airtable-Lookup → echte IDs.
   Fallback bei unbekanntem Kunden: "Mykilos GmbH intern" + Freitext.
   Mehrdeutigkeit → Assistent fragt nach, kein stilles Raten.
3. **Draft Store — Dual**: `ClockodoDraftEntry` (GRDB lokal, user-scoped) +
   Sync → persönliche `Clockodo-EW-{Name}`-Tabelle in Airtable.
   EW-Tabellen-ID kommt aus `Clockodo-Nutzer.Airtable-Entwurf-Tabelle`.
4. **Zwei UI-Orte (beides)**:
   - ClockodoWidget (Heute-Seite): Quick-Add-Sheet + Wochenbalken, kompakt.
   - Zeiten-Tab (Chat-Assistent): NLP-Eingabe, Detailansicht KW, Wochenabschluss.
5. **Confirm → POST**: Bestätigung → `POST /api/v2/entries` mit User-Creds →
   `AuditEntry` (GRDB) + Record in `Clockodo-Buchungen` (Airtable Master-Log).
   EW-Tabelle-Status → "Gebucht". Nie automatisch buchen.
6. **Mail/Kalender-Vorschläge**: Claude liest Gmail + GCal → schlägt Drafts vor
   (quelle: `.calendar`/`.mail`). Gleicher Bestätigungs-Pfad.

**API-Status:** `POST /api/v2/entries` aktiv. `GET /api/v2/clock` aktiv (Timer-Check).
Pflichtfelder POST: `customers_id`, `services_id`, `time_since`, `time_until`, `billable`.

**Offene Entscheidungen vor Implementierung:**
- Wo sitzt die Wochenvorschau? (Neuer Chat-Tab "Zeiten" vs. ClockodoWidget-Erweiterung)
- Format `time_since`/`time_until`: UTC oder lokale TZ? (Clockodo-Dokumentation prüfen)
- Airtable-Schreibrecht für `Clockodo-Buchungen` nach Confirm: welcher Client?
  (Bestehender `AirtableClient` kann Records anlegen — testen)

---

## Partner-App: Kalkulation & Preisschätzung

### 📋 Shared-Airtable-Schema + Merge-Plan (KalkulationsApp)
**Quelle:** User-Entscheidung 2026-06-28. Eine Partner-App für Kalkulation
und Preisschätzung soll gleichberechtigt auf dieselbe Airtable-Base schreiben.
Ein späterer Merge beider Apps ist geplant.

**Status:** Schema vollständig in Airtable angelegt und dokumentiert.
Details: [PARTNER_APP_SCHEMA.md](PARTNER_APP_SCHEMA.md)

**Ownership-Modell (wer schreibt wohin):**
- mykilOS SCHREIBT: Kunden, Projekte, Kontakte, Clockodo-* (alle)
- KalkulationsApp SCHREIBT: Kalkulationen, Kalkulations-Positionen
- BEIDE LESEN: alles

**Neue Airtable-Tabellen (live seit 2026-06-28):**
- `Kalkulationen` (`tblO3y2jdmxDnuiZj`) — Projektkostenrahmen und Angebote.
  Felder: Bezeichnung, Projekt-Nr, Datum, Gültig bis, Status, Gesamt-netto,
  Mehrwertsteuer, Gesamt-brutto, Notiz, App-Quelle.
- `Kalkulations-Positionen` (`tblNamx3cHTus6gtk`) — Einzelpositionen je Kalkulation.
  Felder: Bezeichnung, Kalkulation (Link), Kategorie (Honorar/Material/…),
  Leistung (Link → Clockodo-Leistungen), Menge, Einheit, Stundensatz-Snapshot,
  Einzelpreis, Gesamt, Notiz.

**Neue Felder in bestehenden Tabellen:**
- `Clockodo-Leistungen.Stundensatz (€/h)` (`fld4NBokj4MoOy8Uq`) — von beiden Apps gelesen.
  **Noch leer — Büro-Stundensätze eintragen.**
- `Clockodo-Nutzer.Stundensatz-Override (€/h)` (`fld9Ljvdo20qCwKIe`) — user-spezifische Rate.
  Priorität: Override > Leistungs-Stundensatz.

**Merge-Readiness:**
- Keine App-Präfixe in Tabellennamen nötig (schon merge-fähig)
- Linked Records über echte Airtable-IDs
- Keine Datenmigration beim Merge — Code liest beide Tabellensätze

**Noch offen:**
- Stundensätze für die 8 Leistungsarten manuell eintragen (Bürogeheimnis).
- Architektur der KalkulationsApp selbst (separates Repo/Projekt).

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

## Airtable-Infrastruktur

### ✅ Workspace-Plan: Team (bezahlt) — kein Handlungsbedarf
**Quelle:** Live-Check 2026-06-28 (Airtable-Bereinigungssession).
**Status:** "Mein erster Workspace" läuft auf **Team-Plan (monatlich)** mit AmEx ****3007.
Limits: 50.000 Records/Base (aktuell 13.444), 20 GB Anhänge, 100.000 API-Calls/Monat.
Kein Verschieben der Mastermind-Base nötig. Kein Upgrade nötig.

### ✅ Zulieferpreise (3.383 Beobachtungen): lokal in SQLite — nicht in Airtable
**Quelle:** Expertise-Entscheidung 2026-06-28 (Airtable-Bereinigungssession).
**Entscheidung:** Die mykilO$$-Rohbeobachtungen bleiben lokal. Die V2-Swift-
Destillationspipeline verarbeitet sie in `learning.sqlite` → App liest daraus.
Die existierende `Preis-Beobachtungen`-Tabelle in Mastermind bleibt als Archiv,
ist aber kein operativer Datenpfad.
**Grund:** Rohdaten für ML-Pipeline gehören nicht in Airtable. 3.383 Records × Sync-
Logik × kein Edit-Bedarf = unnötige Komplexität. SQLite ist direkt und schnell.

### ✅ Stundensätze + Bases-Struktur entschieden
**Quelle:** Airtable-Bereinigungssession 2026-06-28.
**Stundensätze:** Airtable als Master (`Clockodo-Leistungen.Stundensatz`), GRDB als Cache.
App sync't beim Start, Kalkulationsmodul liest lokal. Keine doppelte Pflege.
**Bases:** 1 Base bleibt — Mastermind `appuVMh3KDfKw4OoQ`. Kein Split geplant.
Alte Base `appkPzoEiI5eSMkNK` ist stillgelegt — nie anfassen.

### 🚧 Stundensätze — Schätzwerte eingetragen, echte Werte stehen aus (Johannes-Aktion)
**Quelle:** PARTNER_APP_SCHEMA.md offener Punkt, bestätigt 2026-06-28. **Update 2026-07-01
(M5, Konsolidierung):** `Clockodo-Leistungen.Stundensatz (€/h)` war leer und blockierte damit
JEDE Kalkulation (leerer Wert statt Platzhalter). Auf Johannes' Wunsch jetzt mit runden
Schätzwerten befüllt (60–100 €/h, nach Leistungsart gestaffelt: Kundenberatung/Konzeption-CAD
am höchsten, interne Arbeitszeit am niedrigsten) — bewusst nur direkt in Airtable, keine
Schreib-UI in der App (Bürogeheimnis-Regel bleibt: Werte nie in Code/Docs).
**Aktion (weiterhin offen):** Johannes ersetzt die Schätzwerte direkt in Airtable durch die
echten Büro-Stundensätze, sobald er Zeit hat — kein Zeitdruck, das Kalkulationsmodul rechnet
bis dahin mit plausiblen Platzhaltern statt gar nicht.

---

## Architektur & Datenfluss

### 💡 Multi-Base-Architektur v2 + zentrale Datenweichen-Router-Tabelle
**Quelle:** Johannes, 2026-06-30 (während mykilOS 8 Block A). Johannes hat 17 neue, domänen-
getrennte Airtable-Bases angelegt: `mykilOS_Projekte`, `mykilOS_Datenweichen`,
`mykilOS_Handelswaren`, `mykilOS_Onlineshop & Verkauf`, `mykilOS_App Entwicklung`,
`mykilOS_Rechnungen IN`/`OUT`, `mykilOS_Angebote IN`/`OUT`, `mykilOS_Fragebogen & Projekt IN`,
`mykilOS_Adapter ClickUp`/`Slack`/`Sevdesk`/`GoogleDrive`/`Weclapp`, `mykilOS_TRESOR` — sichtbar
über den `list_bases`-Meta-Endpoint mit dem App-PAT, nicht über den Standard-Airtable-MCP.

**Frage:** lohnt sich der Umbau auf Domänen-Bases + eine zentrale Master-/Router-Tabelle, die
maschinenlesbar führt, welche Base/Tabelle für welches Datum die SoR ist (die `Datenstrom-
Handbuch`-Idee konsequent zu Ende gedacht — die App liest Routing-Entscheidungen dann aus dieser
Tabelle statt aus hartcodierten `AirtableClient.writableMap`-Konstanten)?

**Einschätzung:** architektonisch richtig — ein Adapter pro externem System trennt sauber
externe Spiegelung von Geschäftsdaten, genau die Trennung, die den Mastermind↔Artikel-Konflikt
aus Block A verursacht hat (siehe oben). **Umfang ≥ Block C/D, eigener Strang:** 17 Schemata
lesen+verstehen, SoR-Karte v2 entwerfen, gesamtes App-Routing umschreiben (`writableMap`,
`mapProjects`/`mapCustomers`, `ExternalMappingRegistry`, `CartStore`, Intake-Schreibpfad), dazu
intensive Live-Tests (von Johannes selbst gefordert). **Bewusst NICHT in Block A angefasst** —
keine Daten geschrieben/migriert, reine Erkundung.

**Hinweis:** die alte tabu-Base `appkPzoEiI5eSMkNK` (Zuliefererpreise Schätzung) ist über den
App-PAT jetzt ebenfalls sichtbar (gleicher Token, breiterer Zugriff) — das **NO-GO bleibt
unverändert in Kraft**, Sichtbarkeit ist keine Erlaubnis.

**Plan:** erster Schritt einer künftigen, voll budgetierten Session — alle 17 Schemata
domänenweise lesen, Verständnis-Report + konkreten Router-Tabellen-Vorschlag liefern, Johannes
entscheidet, was von Mastermind/Artikel-Base abgelöst wird vs. koexistiert, erst dann bauen.

**🚧 Erster konkreter Schritt getan (2026-07-01, M4-Vertagung):** `mykilOS_Adapter Sevdesk`
(`appcSjFNs1knLeM3G`) hatte noch die unangetastete Airtable-Standardvorlage — jetzt eine Tabelle
`IO-Register` (`tblE8uvRt8nI4utD4`) angelegt, Schema an das bestehende Datenstrom-Handbuch
angelehnt, mit einem Platzhalter-Eintrag `SEVDESK_ADAPTER_IO` (Status „Ausgeklammert", NO-GO
„NIE schreiben") — spiegelt den bestehenden `SEVDESK_INVOICES`-Eintrag im zentralen Datenstrom-
Handbuch, ist aber noch nicht an echten App-Code angebunden. Reine Doku/Struktur-Vorbereitung,
keine Code-Änderung. Bewusst nur DIESE eine Adapter-Base angefasst, nicht alle 17 — der große
Umbau bleibt wie oben beschrieben ein eigener, größerer Strang.

**Performance/Caching-Frage geklärt (2026-06-30):** mehr Bases machen die App NICHT langsamer,
solange das bestehende Lokal-Cache-Muster beibehalten wird (UI liest nie live von Airtable,
immer aus `CachedProjectRegistry`/`CachedBusinessRegistry`/künftigem Artikel-Spiegel — Kosten
skalieren mit Datensätzen pro Sync, nicht mit Anzahl Bases). **Johannes' Entscheidung: Webhook-
basiertes Push ist der bevorzugte Weg** (nicht nur Intervall-Polling) — heißt: für die
Umsetzung braucht es einen kleinen Relay-Server mit öffentlich erreichbarer HTTPS-URL, der
Airtable-Automations/Webhooks empfängt und an die App weiterreicht (eine lokale Mac-App kann
selbst keine Webhook-Ziel-URL sein). **Für die nächste Session vorzubereiten/abzustimmen:** wo
läuft der Relay (eigener kleiner Cloud-Dienst?), wie meldet sich die App dort an, Fallback auf
Polling falls die App offline ist/der Relay nicht erreichbar ist. Sofort-Sync nach eigenem
Write (wie heute bei Intake) bleibt davon unabhängig zusätzlich bestehen. **Push heißt lokal
aktualisieren** (Johannes, 2026-06-30): ein eingehendes Webhook-Event muss den jeweiligen lokalen
Cache (GRDB/FileBackedRepository) genauso befüllen wie ein normaler Sync — der Relay liefert nur
den Auslöse-Impuls „etwas hat sich geändert", die App holt/cached danach wie gewohnt über die
bestehenden `sync(...)`-Pfade. Kein separater Schreibweg am Cache vorbei.

**Weiterer Ausbau angekündigt (Johannes, 2026-06-30):** es wird später zusätzlich eine
**intelligente Alerts-Logik** geben, gestützt auf eigene Airtable-Base(s) für Alerts/Regeln —
Details (welche Trigger, welche Schwellenwerte, wohin gemeldet) noch offen, in der nächsten
vollen Session mit dem Multi-Base-Strang gemeinsam abstimmen.

### 🚨 Budget hat HEUTE zwei Quellen (Mastermind `Project.links.budget` vs. Artikel `BusinessProject.budget`)
**Quelle:** mykilOS 8 Block A, S0-Audit (2026-06-30), code-verifiziert. `CashWidget` liest
`project.links.budget` aus dem Mastermind-Cache (Soll-Wert für den Ist-vs-Budget-Balken). Die
neue `ExternalMappingRegistry` (Block A) liest Budget aus der Artikel-Base als die eigentliche
Geschäfts-Wahrheit (siehe SoR-Karte in `AIRTABLE_DATENFLUSS_AUDIT.md` §3) — beide Felder existieren
parallel und können auseinanderlaufen. **Bewusst NICHT in Block A gefixt** (CashWidget-Umbau wäre
Scope-Creep + Layout-/Regressionsrisiko außerhalb des Block-A-Auftrags). **Plan:** sobald
Geschäftsprojekte über die Projektnummer gebunden sind (siehe `businessOnlyUnbound`-Eintrag
darunter), `CashWidget` auf `ExternalMappingRegistry.resolve(...).business?.budget` umstellen und
`Project.links.budget` als reinen Altlast-Fallback behandeln oder entfernen.

### 🚨 Artikel-Base `Projekte` hat kein `Projektnummer`-Feld → neue Geschäftsprojekte sind unverbindbar
**Quelle:** mykilOS 8 Block A, S0-Audit (2026-06-30), code-verifiziert (Feldnamen aus
`IntakeResultBuilder.mapProjektFelder`: `Projektname`/`Projektstatus`/`Budget`/Adresse — kein
Nummernfeld). `ExternalMappingRegistry` markiert solche Records als `businessOnlyUnbound`
(abrufbar über `unboundBusinessProjects()`).

**Entschieden (Johannes, 2026-06-30):** KEIN Projektname-Fuzzy-Match als Workaround — zu
gefährlich bei Geld-/Statusdaten. Stattdessen exakt das Gegenteil von „selbst reparieren": die
**bestehende Artikel-Projektliste wird von mykilOS/Claude NIE editiert** — weder Schema (neues
Feld) noch Daten (Bestandsrecords). Das ist und bleibt **Daniels Backend-Hoheit** (siehe
`AGENTS.md` „Wer darf was"). Folge: das Feld kommt, wenn Daniel es anlegt — kein Zeitdruck von
unserer Seite, kein Workaround drumherum. Neue Projekte, die Block C (Nomenklatur) zukünftig
selbst per gated CREATE anlegt, können die Projektnummer beim Anlegen mitschreiben, SOBALD das
Feld existiert — das ist kein „Editieren bestehender Daten", sondern ein neues, eigenes CREATE.
Bis dahin bleibt `businessOnlyUnbound` der ehrliche, dauerhafte Zustand für unverbundene
Bestandsprojekte — keine Eile, kein Drängen auf Daniel.

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

### ✅ Hartkodierte Demo-Werte in drei Widgets — behoben
**Quelle:** Code-Audit in Live-Wiring-Session 1. **Behoben 2026-06-27.**
- `ProjectHeroView.swift` — Budget-Balken zeigt jetzt echtes Airtable-Budget
  oder gar nichts (kein Fake-72-%-Wert mehr).
- `FocusWidget.swift` — nutzt echte `projectID` + Registry-Lookup für Titel.
- `CashWidget.swift` — liest echten Signal-Label aus `.reviewSuggested`,
  "In Review übernehmen" schreibt in `AuditStore` (persistiert über Neustarts).

### ✅ Demo-Signal-Buttons emittieren Fake-Signale — behoben
**Quelle:** Code-Audit. **Behoben 2026-06-27.**
`SignalDemoView.swift` (Projektdetail) und `HomeForcePollButton` (Heute-Board)
lösen jetzt echten `DriveOfferWatcher.poll(...)` mit echter `projectID` aus
statt ein hartkodiertes Fake-Signal für `"ME-24"` zu emittieren.

### ✅ RecentActivityWidget zeigt Demo-Daten — behoben
**Quelle:** Code-Audit 2026-06-27. **Behoben 2026-06-27.**
Das Widget zeigte immer dieselben drei erfundenen Einträge ("Zeichnung
Bartresen_v3.pdf · MEYER" etc.) ohne reale Datenquelle. Fix: sauberer
Empty-State statt Demo-Content; echte Implementierung folgt sobald
Drive-Change-Tracking und ClickUp-Listen-IDs umgesetzt sind.

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

### 📋 Airtable-Automation gegen doppelte Projektnummer (Rezept, nicht gebaut)
**Quelle:** 2026-07-01, Nachgang zur Kollisionshärtung (`44270bb`). Die
App-seitige Live-Drive-Kollisionsprüfung (`reserviereKollisionsfreieNummer`)
schließt nur die Lücke "Drive-Ordner ohne Airtable-Zeile". Zwei doppelte
Airtable-**Zeilen** mit derselben Projektnummer (z. B. durch einen manuellen
Airtable-Edit) erkennt sie nicht — das bräuchte eine Airtable-native
Automation. Mein Airtable-MCP-Toolset kann den Automation-Editor nicht
ansteuern (nur Base/Tabelle/Feld/Record-CRUD), daher hier als manuelles
Rezept für den Airtable-Automation-Editor (Web-UI, Base "mykilOS Mastermind"
→ Automations → "+ Create automation"):
1. **Trigger:** "When a record is updated" → Tabelle `Projekte`, beobachtetes
   Feld `Projektnummer`.
2. **Action 1 — Find records:** Tabelle `Projekte`, Filter
   `Projektnummer = {Trigger record → Projektnummer}`, Sortierung egal.
3. **Action 2 — Condition:** nur fortfahren, wenn "Find records" **mehr als
   1** Treffer liefert (sonst ist es die triggernde Zeile selbst).
4. **Action 3 — Send email/Slack-Nachricht** (oder ein Feld `Duplikat-
   Warnung` per "Update record" setzen): Text z. B. "Doppelte Projektnummer
   {Projektnummer} in {Anzahl Treffer} Zeilen — bitte manuell klären."
Ergänzt das bereits gebaute `Format-Check`-Formelfeld (prüft nur die eigene
Zeile gegen das `JJJJ_NNN_...`-Schema, siehe BENUTZERHANDBUCH.md) um den
zeilenübergreifenden Fall. Aufwand ca. 10 Minuten im Airtable-UI, nicht
terminiert — bei Bedarf einfach nachbauen.

---

## Security & Onboarding

### 📋 User-Identität nach Google-Login
**Quelle:** Team-Review 2026-06-28 (S10 Learning Session).
**Problem:** Nach erfolgreichem Google-Login weiß die App nicht wer eingeloggt ist.
Kein Name, keine E-Mail, kein Avatar sichtbar. Nutzer kann nicht erkennen ob er mit
dem richtigen Account verbunden ist — Onboarding-Killer und latentes Sicherheitsproblem.
**Plan (Session A aus MASTER_HANDOFF_CODEX.md):**
`GoogleAuthService` → nach Token-Tausch `GET /oauth2/v2/userinfo` → `GoogleUserInfo(email, displayName)`
→ Keychain-Cache → `AppState.currentGoogleUser` → Anzeige in `SidebarView` unten.
Test: `GoogleUserInfoTests` — JSON-Parsing ohne Netzwerk.

### 🔴 Keychain-Bug: `baseID` enthält PAT statt Base-ID
**Quelle:** Bekannt seit Post-Akt-5, bestätigt 2026-06-28.
**Problem:** Im Keychain-Feld `baseID` (Service `com.mykilos6.airtable`) steht
fälschlicherweise ein zweites PAT-Token statt der Base-ID `appuVMh3KDfKw4OoQ`.
Airtable-Sync schlägt still fehl — kein Nutzer kann das selbst debuggen.
**Fix:** Validierung beim Speichern in Settings (`baseID` muss mit `app` beginnen) +
klare Fehlermeldung. Sofortmaßnahme: manuell in App-Einstellungen → Airtable
Base-ID-Feld → `appuVMh3KDfKw4OoQ` eintragen.

### 📋 `AirtableSyncService.swift` löschen
**Quelle:** Code-Audit S10/S12 2026-06-28.
**Problem:** `Sources/MykilosServices/Airtable/AirtableSyncService.swift` enthält
drei Regelverstöße: ENV-Secrets, falsche Base `appkPzoEiI5eSMkNK`, `DispatchSemaphore`.
Datei ist als obsolet markiert, aber noch nicht entfernt.
**Plan:** Datei löschen, sicherstellen dass nichts darauf referenziert, Build grün.

### 💡 Onboarding-Flow für neue Nutzer
**Quelle:** Team-Review 2026-06-28 (S10 Learning Session).
**Problem:** Neuer Nutzer öffnet die App → sieht Demo-Projekte → weiß nicht was er
verbinden soll oder in welcher Reihenfolge. Kein geführter Einstieg.
**Idee:** "Erste Schritte"-Checklist in Settings oder Launch-Screen beim ersten Start:
1. Google-Account verbinden → 2. Airtable-Base eintragen → 3. Clockodo-Key (optional)
→ 4. Claude API-Key (optional). Fortschrittsanzeige pro Schritt.

### 💡 SQLite-Backup / Archiv-Log
**Quelle:** Team-Review 2026-06-28.
**Problem:** GRDB-Datenbank liegt in `Application Support` — kein automatisches Backup.
Wenn jemand die App löscht oder die DB korrupt wird, ist der gesamte Audit-Log weg.
**Idee:** Täglicher automatischer SQLite-Snapshot nach
`~/Library/Application Support/mykilOS/Backups/YYYY-MM-DD.sqlite`.
Maximal 30 Snapshots behalten (älteste löschen). "Backup wiederherstellen"-Option in Settings.

### 💡 Crash-Reporting
**Quelle:** Team-Review 2026-06-28.
**Problem:** Kein Crash-Reporting-System vorhanden. Abstürze werden nur bekannt wenn
der Nutzer sie meldet.
**Idee:** Optionen abwiegen — macOS-native (`NSApplication.shared.reportException` +
lokales Crash-Log in `Application Support`) vs. leichtgewichtiger externer Dienst
(Sentry o.ä.). Wichtig: local-first-Prinzip — keine Daten nach außen ohne explizite
Nutzer-Zustimmung. Mindestlösung: Crash-Log lokal schreiben + "Fehlerprotokoll zeigen"-
Button in Settings.

### 💡 Cache-Management
**Quelle:** Team-Review 2026-06-28.
**Problem:** Google/Airtable-Daten werden in GRDB gecacht, aber kein TTL definiert,
kein "Cache leeren"-Button in Settings. Kein explizites Cache-Management.
**Idee:** "Cache leeren"-Option in Settings pro Integration (Google / Airtable).
TTL pro Datentyp definieren (z.B. Drive-Dateiliste: 5 Min, Kalender: 15 Min,
Kontakte: 1 Stunde). Offline-Indikator wenn Cache veraltet ist.

---

## Hinweis für zukünftige Sessions

Dieses Dokument ist **additiv** — neue Ideen unten/in der passenden
Sektion ergänzen, Status bei Fortschritt ändern, nichts löschen (außer bei
❌ Verworfen kurz die Begründung ergänzen und stehen lassen, das ist auch
eine Information). Wenn ein Punkt in einem Handoff im Detail beschrieben
ist, hier nur kurz zusammenfassen + verlinken, nicht duplizieren.
