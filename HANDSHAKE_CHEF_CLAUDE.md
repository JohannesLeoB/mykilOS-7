# 🤝 Handshake — für den Claude-Agenten von Johannes' Chef

> **An dich, fremder Claude-Agent:** Du bekommst dieses Repo gerade zum ersten Mal zu
> sehen, wahrscheinlich als gezippter Ordner. Dieses Dokument ist dafür da, dich in
> wenigen Minuten auf denselben Stand zu bringen wie die Session, die es geschrieben
> hat — damit ihr zwei parallele Entwicklungsstränge sicher zusammenführen könnt,
> statt Arbeit zu verlieren oder zu verdoppeln.

```
Exportiert:  2026-07-01
Branch:      feat/mykilos8-block-d-provisioning
HEAD:        36c2c7e
GitHub:      https://github.com/JohannesLeoB/mykilOS-7 (privat) — falls dein Nutzer
             dir Zugriff geben kann: DAS ist der bessere Weg (siehe §5), nicht der Zip.
Build:       ✅ swift build grün
Tests:       ✅ 748 grün (100 Suites)
App-Bundle:  dist/mykilOS 8.0.0.app + dist/mykilOS-8.0.0.dmg (in diesem Export enthalten)
```

**Lies zuerst [HYPERBUILD.md](HYPERBUILD.md)** — die kondensierte Ein-Seiten-Zusammenfassung
der ganzen App (Architektur, aktueller Stand, To-do-Liste). Dieses Dokument hier ergänzt
NUR den Handshake-Teil: was die beiden Stränge sind, was schon abgeglichen wurde, was noch
offen ist.

---

## 1 · Warum dieses Dokument existiert

Johannes' Chef arbeitet parallel mit dir (oder einer anderen Claude-Session) an mykilOS.
Diese Session (Claude Sonnet 5, Konsolidierung zu „mykilOS 8.0") hat beim eigenen
Branch-Aufräumen bereits **zwei mutmaßlich zu deinem/eurem Strang gehörende Branches**
auf demselben GitHub-Remote gefunden:

- `fix/intake-warenkorb-airtable-422` — eine **unabhängige, eigene Implementierung**
  von „mykilOS 8 Block D" (Projekt-Provisionierung), gebaut auf denselben Block-A/B/C-
  Commits wie unser Strang, aber ab Block D eigenständig weitergeführt. Enthält u. a.
  einen eigenen HTTP-422-Fix (ähnliches Problem, andere Lösung als unserer).
- `handoff/workbasket-checkout-architecture-2026-07-01` — ein vollständiges,
  eigenständiges **Architekturpapier** für eine generische „WorkBasket/Checkout"-
  Pipeline (DataObject→WorkBasket→CheckoutRun→Preview→Review→Audit), 18 durchgeplante
  I/O-Einträge, **noch 0 Zeilen Code** — bewusst laut eigener Stop-Regel („kein
  Feature-Code vor Johannes' Freigabe").

**Falls diese beiden Branches von dir/deiner Session stammen:** Bitte bestätige das
Johannes gegenüber, dann können wir den Rest dieses Dokuments als gemeinsame
Abgleichs-Checkliste nutzen. Falls nicht — sag uns, woher sie stammen, das ist für
uns ebenfalls eine offene Frage.

---

## 2 · Was in diesem Export bereits geklärt ist (nicht neu verhandeln)

Diese Session hat `fix/intake-warenkorb-airtable-422` Datei für Datei gegen den
aktuellen Stand verglichen:

- **`Provisioning.swift` ist byte-identisch** zwischen beiden Branches — vermutlich
  derselbe Auftrag/Brief, unabhängig zweimal umgesetzt.
- Alle anderen Unterschiede (Fehlerdiagnose `AirtableError.validationFailed`,
  TEST-Projekte-Airtable-Whitelist, `CartStore`-Feld-NAME-Fix, Entfernung des
  nicht-existenten `Budget`-Feldes) waren auf **unserem** Branch bereits weiter/
  korrekter — nichts davon musste übernommen werden.
- Die **einzige wertvolle, fehlende Ergänzung** war eine echte Test-UI
  (`ProvisioningTestView.swift`, in der Schaltzentrale) — die haben wir bereits
  **portiert und committed** (Commit `ad77513`).

→ **Der Block-D-Teil ist aus unserer Sicht erledigt.** Falls dein Strang seitdem an
`fix/intake-warenkorb-airtable-422` weitergearbeitet hat, bitte VOR einem Merge
nochmal gegen unseren aktuellen `feat/mykilos8-block-d-provisioning`-Stand
gegenchecken (Diff, nicht blind übernehmen — siehe die harte Lektion in §4).

## 3 · Was noch eine gemeinsame Entscheidung braucht

**WorkBasket/Checkout-Architektur.** Konzeptionell überschneidet sich das mit unserem
geplanten „Block F" (Warenkorb-/Abnahme-Widgets) und Teilen von Block E. Bevor daran
Code entsteht, muss geklärt werden:
- Wird der Rolling Plan (Block E→F→G, siehe HYPERBUILD.md §6) wie geplant weitergebaut,
  oder auf das generische WorkBasket-Pipeline-Modell umgestellt?
- Falls WorkBasket: von welchem Branch aus wird das echte Fundament (Block A–D:
  `ExternalMappingRegistry`, `WriteShadowRecorder`, `ProvisioningLedger`,
  `ProjektProvisioningService`) übernommen? Die WorkBasket-Branch selbst ist von
  `main`/v7.7.2 abgeleitet und kennt diese Klassen NICHT im eigenen Code — das
  WorkBasket-eigene Risiko-Dokument (`SYSTEM_TRUTH_MAP.md` auf dieser Branch) nennt das
  selbst als offenes Risiko.

**Diese Entscheidung trifft Johannes** (ggf. gemeinsam mit seinem Chef) — keine der
beiden Claude-Sessions sollte hier vorgreifen und Code schreiben, bevor das steht.

## 4 · Harte Lektionen aus dieser Session (bitte respektieren)

1. **Nie zwei parallele Block-D-artige Implementierungen blind mergen.** Diff zuerst,
   Datei für Datei — in diesem Fall war es zum Glück konfliktfrei (0 Merge-Marker in
   einem `git merge-tree`-Trockenlauf), aber das war Glück, kein Automatismus.
2. **`AirtableClient.fetchRecords` liefert Felder standardmäßig per NAME, nicht per ID**
   (`returnFieldsByFieldId` wird nie gesetzt) — ein Read-Match über Feld-IDs trifft NIE.
   Betrifft `CartStore` (Archivierung/Versionierung lief deshalb lange ins Leere).
3. **Airtable-Feldtypen nie erraten.** Number-Felder nie als String senden, Single-
   Select nur mit exakt konfiguriertem Label, Link-to-record-Felder nur mit echten
   Record-IDs (nie roher String) — jeweils sonst HTTP 422. Vor jeder neuen Tabelle das
   echte Schema live verifizieren (Technik: über einen bereits laufenden Read
   `Set(records.flatMap(\.keys))` unionieren — es gibt keinen direkten Schema-Lesezugriff).
4. **Externe Daten sind heilig** (siehe CLAUDE.md „Absolute Regeln"): Sevdesk nie lesen/
   schreiben über den offiziellen read-only Client hinaus; die Artikel-Projektliste/
   -Kundenliste (Schema UND Daten) ist Daniels Hoheit — nie selbst ein Feld ergänzen,
   nie Fuzzy-Match als Workaround; Airtable-Records nie löschen (nur Status-/Archivfeld).
5. **`main` ist geschützt.** Tag `v7.0.0` (`e629e84`) ist der unantastbare Safe State.
   Push/Merge nach `main` macht **nur Johannes** — keine Session (auch nicht diese, auch
   nicht deine) merged selbstständig.

## 5 · Empfehlung für den weiteren Ablauf

Ein Zip-Export ist ein Schnappschuss — verliert Historie, Branches, Commit-Nachrichten.
**Falls dein Nutzer dir Zugriff auf `github.com/JohannesLeoB/mykilOS-7` geben kann**,
wäre das der robustere Weg: du liest direkt die genannten Branches inkl. voller Historie,
statt aus einem Zip zu rekonstruieren, was zusammengehört. Diese Empfehlung ändert nichts
an dem, was du mit dem Zip tun kannst — sie ist nur ein Hinweis, falls es einfacher geht.

Unabhängig vom Übertragungsweg: bitte vor jeder Code-Änderung `swift build && swift test`
laufen lassen (748 Tests, ~3 s) und **keinen Push/Merge nach `main`** ohne Johannes.

---

## 6 · Kurz-Architektur (Kopie aus HYPERBUILD.md §2, für den Fall dass nur dieses eine Dokument gelesen wird)

```
App → Widgets → Design        |  Services → Kit        |  Integrations → Kit
MykilosKit       importiert NIE SwiftUI/GRDB (reine Domain + Persistence + Signals)
MykilosWidgets   importiert NIE GRDB; Widgets reden NIE direkt → nur StudioContext.emit()
Schreibvorgänge  kommen NIE aus Views — nur über Stores; jeder Write throws; SaveState sichtbar
Persistenz       GRDB; Cold-Start-Test Pflicht (schreiben→neue Instanz→lesen→identisch)
Tokens           SwiftLint erzwingt: Font.myk… / MykColor.… — keine .system()/Color(red:)
Secrets          nur Keychain, pro Nutzer isoliert; Clockodo nur Private Area
```

Persönliches macOS-Cockpit (SwiftUI, local-first) für Studio-Projektarbeit. Airtable ist
System-of-Record (kein Sync-Backend), Google Drive/Calendar/Contacts/Gmail read-mostly,
ClickUp/Clockodo/Sevdesk je ein eigener Adapter, Claude/Anthropic als Assistent mit
Tool-Use. Vollständige Nutzerfunktionen: [docs/BENUTZERHANDBUCH.md](docs/BENUTZERHANDBUCH.md).
Vollständiges Gedächtnis (Historie, Entscheidungen, Team-Regeln): [CLAUDE.md](CLAUDE.md).

*Erstellt von Claude Sonnet 5 während der mykilOS-8.0-Konsolidierungs-Session, 2026-07-01.
Sicherheits-Check vor Export durchgeführt: keine Secrets/API-Keys im Repo gefunden
(`.gitignore` schließt `.build/`/`dist/`/`*.zip` aus, Keychain-only-Regel eingehalten).*
