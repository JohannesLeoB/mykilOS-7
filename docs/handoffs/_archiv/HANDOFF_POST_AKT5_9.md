# Handoff — Post-Akt 5, Aufgabe 9: Drive-Offer-Watcher live (offerDetected)

**Status:** abgeschlossen

---

## Was gebaut wurde

Das Signal `offerDetected` — der lange als „geplant" markierte **Drive-Webhook** —
hat jetzt eine **echte Live-Quelle**. Statt nur per Signal-Demo-Button erkennt
der neue **`DriveOfferWatcher`** neue Angebots-/Rechnungs-PDFs im verlinkten
Drive-Ordner eines Projekts und feuert das Signal in den bestehenden
Mediator-/CashWidget-Pfad.

Ein echter Google-Push-Webhook (`files.watch`) bräuchte eine öffentliche
Callback-URL und damit ein Backend — **mykilOS ist local-first**. Deshalb pollt
der Watcher den Ordner read-only über das vorhandene `files.list`
(`GoogleDriveClient`). Damit ist auch der letzte geplante Integrations-Anschluss
live; alle Widgets lesen echte Daten und die Integrations-Landkarte ist
vollständig.

Der `SignalDemoView`-Button bleibt als sofort auslösbarer **Showcase** erhalten:
er erzeugt dasselbe `offerDetected`, ohne auf ein echtes neues PDF zu warten.

## Kernsemantik

- **Baseline beim ersten Lauf:** `poll(...)` markiert beim ersten Aufruf alle
  vorhandenen Treffer als „gesehen" und meldet **nichts** — sonst flutete beim
  Öffnen eines Projekts jedes alte Angebot als „neu". Erst danach erzeugt ein
  wirklich neu aufgetauchtes PDF ein Signal.
- **Was zählt als Angebot:** ein PDF (`mimeType == application/pdf`), dessen Name
  ein Schlüsselwort enthält — `angebot`, `rechnung`, `kostenvoranschlag`,
  `offer`, `invoice`. Bewusst konservativ: lieber einen Beleg verpassen als jeden
  Upload melden.
- **Kein Doppel-Report:** gesehene IDs werden in `seen` gehalten; ein bereits
  gemeldetes PDF feuert nicht erneut.
- **Fehler werden geschluckt:** ein Hintergrund-Poll darf die UI nie mit
  Fehlerzuständen stören (`notConnected`/Netzwerk → leeres Ergebnis). Fehler-
  zustände zeigt das `DriveWidget` selbst. Leerer/fehlender Ordner → keine Signale.
- **Signale bleiben VORSCHLÄGE:** `offerDetected` → Mediator leitet
  `reviewSuggested` ab → CashWidget zeigt einen Hinweis. Es wird **nie**
  geschrieben — das liefe über Action-Card → Bestätigung → Audit.

## Neue / geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosServices/Google/DriveOfferWatcher.swift` | **Neu.** `@MainActor @Observable`. `poll(projectID:folderID:) async -> [WidgetSignal]` (Baseline-Logik, Dedup über `seen`). Reine, testbare Kernlogik: `offerKeywords`, statisch `detectOffers(in:)`/`isOffer(_:)`. Injizierbarer `GoogleDriveFetching`-Client. |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | `@State offerWatcher` + `offerPollInterval = .seconds(60)`. Neuer `.task(id: driveFolderID)`-Loop: pollt solange das Projekt offen ist, `context.emit(...)` für jedes neue Signal. |
| `Sources/MykilosApp/Detail/SignalDemoView.swift` | Kommentar aktualisiert: `DriveOfferWatcher` ist jetzt die Live-Quelle, der Button bleibt Showcase fürs gleiche Signal. |
| `Tests/MykilosServicesTests/DriveOfferWatcherTests.swift` | **Neu.** 5 Tests + `FakeDriveClient`. |
| `docs/architecture/mykilOS Mac_Systemarchitektur.html/.pdf` | Drive-Webhook von „GEPLANT" auf **LIVE** (Landkarte-Pfeil/Box „Drive-Offer-Watcher", Karte S.1, Steckbrief S.5, Signal-Sektion, Trigger-Matrix-Zeile). PDF neu (9 S.). |
| `CLAUDE.md` | „Wo wir stehen", Akt-Tabelle (Aufgabe 9), Target-Struktur, „Nächste Schritte", Doku-Index. |

## Tests

- `DriveOfferWatcherTests`:
  - `detectOffersErkenntNurAngebotsPDFs` — nur PDFs mit Schlüsselwort.
  - `ersterPollLegtNurBaselineAnUndMeldetNichts`.
  - `zweiterPollMeldetNurNeuesAngebot` — Projekt/Label korrekt im Signal.
  - `gleichesAngebotWirdNichtZweimalGemeldet`.
  - `fehlerOderLeererOrdnerMeldetNichts` — Auth-Fehler & leerer/leerer-Handle.
- `FakeDriveClient` (`GoogleDriveFetching, @unchecked Sendable`) mit mutierbarer
  `files`-Liste und optionalem `error`.

## Regeln eingehalten

- **Architektur:** Watcher liegt in `MykilosServices` (kein GRDB, kein SwiftUI-
  Zwang); nutzt den bestehenden read-only `GoogleDriveClient`. Kein neuer
  Netzwerkcode, kein Schreibpfad.
- **Widgets reden nie direkt:** der Watcher emittiert ausschließlich über
  `StudioContext.emit(...)`; die Reaktion läuft über den vorhandenen Mediator.
- **Secrets:** keine neuen Credentials — der Drive-Zugang nutzt die bestehenden
  Google-Tokens im Keychain. `driveFolderID` bleibt Referenz-Handle.
- **Signale sind Vorschläge:** kein Schreibvorgang; reiner Lese-Poll.

## Verifikation

- `swift build` — warnungsfrei.
- `swift test` — **114 Tests grün** (109 + 5 neue DriveOfferWatcher-Tests).
- Token-Disziplin manuell geprüft (keine `.font(.system`/`Color(red:`/`Color(hex:`
  in geänderten Views; SwiftLint nicht im PATH dieser Umgebung).
- `./docs/architecture/build_pdf.sh` — PDF neu, weiterhin 9 Seiten.

## Offen / nicht hier testbar

- Echter Drive-Abruf mit verbundenem Account + realem neuen PDF bleibt ein
  **manueller Beta-Check** (Tests nutzen kein echtes Keychain/Netzwerk).
- Das Poll-Intervall (60 s) ist bewusst gemächlich; falls in der Praxis schnellere
  Reaktion gewünscht ist, in `ProjectDetailView.offerPollInterval` nachziehen.
- Der Watcher pollt nur den Ordner des **aktuell offenen** Projekts (an den
  `.task`-Lebenszyklus der Detailseite gebunden). Ein globaler Hintergrund-Poll
  über alle Projekte ist bewusst nicht gebaut.
- Die Schlüsselwort-Heuristik ist absichtlich einfach; ein Mehr-Sprachen-/
  Mehr-Muster-Ausbau (oder MIME-Erweiterung über PDF hinaus) wäre eine spätere
  Verfeinerung.

## Nächster Schritt nach Plan

Kein verdrahteter Integrations-Anschluss mehr offen. Verbleibende GEPLANT-Punkte
sind reine App-Feature-Seiten (Marken & Daten, Angebote, Timeline, Material) —
eigene Oberflächen, keine Datenquellen.
