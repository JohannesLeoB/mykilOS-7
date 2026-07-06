# Handoff — Post-Akt 5, Aufgabe 10: Angebote-Tab live

**Status:** abgeschlossen

---

## Was gebaut wurde

Der Projekt-Detail-Tab **„Angebote"** war bisher ein „in Vorbereitung"-
Platzhalter (`ComingTabView`). Er zeigt jetzt **live** die Angebots-/Rechnungs-
PDFs („Belege") aus dem im Projekt verlinkten Drive-Ordner.

Das baut direkt auf Aufgabe 9 auf: Der `DriveOfferWatcher` *erkennt* Belege
bereits fürs `offerDetected`-Signal — die Tab *zeigt* nun dieselben Treffer.
Erkannt wird über **`DriveOfferWatcher.detectOffers`** (dafür `public` gemacht),
also genau dieselbe Heuristik wie das Signal. **Eine Quelle der Wahrheit:** keine
zweite, abweichende Erkennung in der UI.

Read-only: nur Metadaten + Link zum Öffnen im Browser, nie Schreiben, kein
Download.

## Neue / geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosApp/Detail/OffersTabView.swift` | **Neu.** `OffersTabView` (Tab), privater `@Observable OffersLoader` (read-only Fetch über `GoogleDriveClient`, Filter via `DriveOfferWatcher.detectOffers`), `OfferRow`. Rendert über den geteilten `WidgetContainer` (alle Renderstates), Quellzeile „GOOGLE DRIVE · N BELEGE", Retry. |
| `Sources/MykilosServices/Google/DriveOfferWatcher.swift` | `offerKeywords`/`detectOffers`/`isOffer` von intern auf **`public`** gehoben (geteilte Erkennung Signal ↔ Tab). |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | `tabContent`: neuer `case .offers → OffersTabView(projectID:driveFolderID:)`. |
| `docs/architecture/mykilOS Mac_Systemarchitektur.html/.pdf` | Projekt-Tab „Angebote" von GEPLANT → **LIVE**; Notiz, dass die Tab `DriveOfferWatcher.detectOffers` teilt. PDF neu (9 S.). |
| `CLAUDE.md` | „Wo wir stehen", Akt-Tabelle (Aufgabe 10), Target-Struktur, „Nächste Schritte", Doku-Index. |

## Renderstates

Über den geteilten `WidgetContainer`:
- **content** — Liste der Belege (Name, relatives Datum, Öffnen-Glyph).
- **empty** — kein Drive-Ordner verlinkt **oder** keine Belege im Ordner.
- **loading** — während des Fetch.
- **permissionRequired** — `GoogleDriveError.notConnected` (Google nicht verbunden),
  mit „Erneut versuchen".
- **error** — sonstiger Fehler, mit „Erneut versuchen".

## Regeln eingehalten

- **Architektur:** View in `MykilosApp`, nutzt den bestehenden read-only
  `GoogleDriveClient` aus `MykilosServices`; kein neuer Netzwerkcode, kein GRDB,
  kein Schreibpfad.
- **Quelle sichtbar:** Quellzeile + SourceChip (`.drive`).
- **Keine Doppel-Logik:** Belegerkennung ausschließlich über die geteilte
  `DriveOfferWatcher.detectOffers`.
- **Token-Disziplin:** nur `Font.myk…`/`MykColor.…`, kein `.font(.system`/
  `Color(red:`/`Color(hex:`.

## Verifikation

- `swift build` — warnungsfrei.
- `swift test` — **114 Tests grün** (unverändert; die einzige neue Code-Logik
  ist die geteilte `detectOffers`, abgedeckt durch
  `detectOffersErkenntNurAngebotsPDFs` — jetzt über die `public`-Methode).
- `./docs/architecture/build_pdf.sh` — PDF neu, weiterhin 9 Seiten.

## Offen / nicht hier testbar

- Echter Drive-Abruf mit verbundenem Account bleibt ein **manueller Beta-Check**
  (kein App-Test-Target; Tests nutzen kein echtes Keychain/Netzwerk).
- Die Erkennung ist namensbasiert (PDF + Schlüsselwort). Ein inhaltsbasierter
  Ansatz (PDF-Text, MIME über PDF hinaus) wäre eine spätere Verfeinerung —
  bewusst nicht gebaut.
- Sortierung/Gruppierung (z. B. nach Datum) ist noch nicht implementiert; die
  Liste folgt der Drive-Antwortreihenfolge.

## Nächster Schritt nach Plan

Weitere reine Oberflächen ohne neue Datenquelle: Projekt-Tabs Dateien/Timeline/
Material und die Sidebar-Module Marken & Daten / Angebote. Kein verdrahteter
Integrations-Anschluss mehr offen.
